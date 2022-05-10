//
//  ViewController.swift
//  GenActiontool
//
//  Created by alex on 2022/5/6.
//
import UIKit
import HomeKit

typealias CellValueType = NSCopying

class ViewController: UIViewController {
    var homes = [HMHome]()
    let homeManager = HMHomeManager()
    //--
    var home: HMHome? = nil
    var accessories = [HMAccessory]()
    var discoveredAccessories = [HMAccessory]()
    //--
    var actionSet: HMActionSet?
    var aAction: HMAction?
    //--
    let targetValueMap = NSMapTable<HMCharacteristic, CellValueType>.strongToStrongObjects()
    /// A dispatch group to wait for all of the individual components of the saving process.
    let saveActionSetGroup = DispatchGroup()
    var saveError: Error?
    override func viewDidLoad() {
        super.viewDidLoad()
        homeManager.delegate = self
        print ("(1)")
        addHomes(homeManager.homes)
        
       
    }
    
    func addHomes(_ homes: [HMHome]) {
      self.homes.removeAll()
      for home in homes {
        self.homes.append(home)
      }
    }
    
    private func loadAccessories() {
      guard let homeAccessories = home?.accessories else {
        return
      }

      for accessory in homeAccessories {
        if let characteristic = accessory.find(serviceType: HMServiceTypeSwitch, characteristicType: HMCharacteristicMetadataFormatBool) {
          accessories.append(accessory)
          accessory.delegate = self
          characteristic.enableNotification(true, completionHandler: { (error) -> Void in
            if error != nil {
              print("Something went wrong when enabling notification for a chracteristic.")
            }
          })
        }
      }
    }
    
    func reloadDisplayData(for home: HMHome?) {
        if let home = home {
            for serv in home.servicesWithTypes([HMServiceTypeSwitch])! {
                print ("*serv = \(serv)")
                let characteristics = serv.characteristics
                print ("-characteristics = \(characteristics)")
                for chara in characteristics {
                   
                    if let value = chara.value, let name = chara.service?.name
                        ,let format = chara.metadata?.format , let desc=chara.metadata?.manufacturerDescription{
                        print (" - chara.metadata?.format=\(format)")
                        print (" - chara.service.name=\(name)")
                        print (" - chara.value=\(value)")
                        print (" - chara.metadata?.description=\(desc)")
                        print ("---")
                        
                        if  desc == "Power State" {
                            print ("Before name:\(name)")
                            let afterName = name.replacingOccurrences(of: "00", with: "")
                            print ("After name:\(afterName)")
                            
                            
                            
                            if let target = targetValueForCharacteristic(chara) {
//                                cell.setCharacteristic(characteristic, targetValue: target)
                                aAction = HMCharacteristicWriteAction(characteristic: chara, targetValue: target)
                            }
                            
                            
                           

                            
                            actionSet?.addAction(aAction!, completionHandler: { _ in
                                print ("*done")
                            })
                            
                            home.addActionSet(withName: afterName) { actionSet, error in
                                if let error = error {
                                    print("HomeKit: Error creating action set: \(error.localizedDescription)")
    
                                }
                                else {
                                    // There is no error, so the action set has a value.
                                 
//                                    self.saveActionSet(actionSet!,chara)
                                    self.saveActionSet(actionSet!, chara: chara)
                                }
                            }
                        }

                    }
                    
                }
                print ("===")
               
            }
            

            

        }
    }
    
    func targetValueForCharacteristic(_ characteristic: HMCharacteristic) -> CellValueType? {
        if let value = targetValueMap.object(forKey: characteristic) {
            return value
        }
        else if let actions = actionSet?.actions {
            for case let writeAction as HMCharacteristicWriteAction<CellValueType> in actions {
                if writeAction.characteristic == characteristic {
                    return writeAction.targetValue
                }
            }
        }

        return nil
    }
    
    func saveActionSet(_ actionSet: HMActionSet, chara: HMCharacteristic) {
//        let actions = actionsFromMapTable(targetValueMap)
        
        //這邊自己組裝
        let a = HMCharacteristicWriteAction(characteristic: chara, targetValue: 1 as NSCopying)
//        for action in actions {
            saveActionSetGroup.enter()
            addAction(a, toActionSet: actionSet) { error in
                if let error = error {
                    print("HomeKit: Error adding action: \(error.localizedDescription)")
                    self.saveError = error
                }else{
                    print ("Create sense name ok ")
                }
                self.saveActionSetGroup.leave()
            }
//        }
    }
    
    func actionsFromMapTable(_ table: NSMapTable<HMCharacteristic, CellValueType>) -> [HMCharacteristicWriteAction<CellValueType>] {
        return targetValueMap.keyEnumerator().allObjects.map { key in
            let characteristic = key as! HMCharacteristic
            let targetValue =  targetValueMap.object(forKey: characteristic)!
            return HMCharacteristicWriteAction(characteristic: characteristic, targetValue: targetValue)
        }
    }
    
    func addAction(_ action: HMCharacteristicWriteAction<NSCopying>, toActionSet actionSet: HMActionSet, completion: @escaping (Error?) -> Void) {
        if let existingAction = existingActionInActionSetMatchingAction(action) {
            existingAction.updateTargetValue(action.targetValue, completionHandler: completion)
        }
        else {
            //action diy
//            let action = HMCharacteristicWriteAction(characteristic: characteristic, targetValue: true)
            actionSet.addAction(action, completionHandler: completion)
        }
    }
    func existingActionInActionSetMatchingAction(_ action: HMCharacteristicWriteAction<CellValueType>) -> HMCharacteristicWriteAction<CellValueType>? {
        if let actionSet = actionSet {
            for case let existingAction as HMCharacteristicWriteAction<CellValueType> in actionSet.actions {
                if action.characteristic == existingAction.characteristic {
                    return existingAction
                }
            }
        }
        return nil
    }
}

//更新完抓到所有的home
extension ViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
      
      for home1 in manager.homes {
        print ("(2)")
        print ("* read home:\(home1)")

        reloadDisplayData(for: home1)
        print ("* accessories=\(accessories)")
      }
      
  }
}

//--
extension ViewController: HMAccessoryDelegate {
  func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
//    collectionView?.reloadData()
  }
}

extension ViewController: HMAccessoryBrowserDelegate {
  func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
    discoveredAccessories.append(accessory)
  }
}

extension HMAccessory {
  func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
    return services.lazy
      .filter { $0.serviceType == serviceType }
      .flatMap { $0.characteristics }
      .first { $0.metadata?.format == characteristicType }
  }
}
