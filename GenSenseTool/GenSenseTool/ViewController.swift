//
//  ViewController.swift
//  GenActiontool
//
//  Created by alex on 2022/5/6.
//
import UIKit
import HomeKit

class ViewController: UIViewController {
    var homes = [HMHome]()
    let homeManager = HMHomeManager()
    //--
    var home: HMHome? = nil
    var accessories = [HMAccessory]()
    var discoveredAccessories = [HMAccessory]()


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
//      collectionView?.reloadData()
        print ("* self.homes=\(self.homes)")
        
        
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

//      collectionView?.reloadData()
    }
    
    func reloadDisplayData(for home: HMHome?) {
        var processServiceName = ""
        if let home = home {
            for serv in home.servicesWithTypes([HMServiceTypeSwitch])! {
                print ("*serv = \(serv)")
                let characteristics = serv.characteristics
                print ("-characteristics = \(characteristics)")
                for chara in characteristics {
                   
                    if let value = chara.value, let name = chara.service?.name
                    ,let format = chara.metadata?.format{
                        print (" - chara.metadata?.format=\(format)")
                        processServiceName = name
                        print (" - chara.service.name=\(name)")
                        print (" - chara.value=\(value)")
                        print ("---")
                    }
                    
                }
                print ("===")
               
            }
            let service = home.servicesWithTypes([HMServiceTypeSwitch])?[1]
            print ("* service =\(service)")
            //On    00000025-0000-1000-8000-0026BB765291
            let candidates = service?.characteristics
                .filter { $0.characteristicType != "" }

            guard let powerState = candidates?.first else {
                return
            }

            print("# powerState: \(String(describing: powerState.value))")
            
//            // powerState.value に取得済みのvalueが入っているが
//            // readValueでデバイスから最新のvalueを再読み込み可能
//            powerState.readValue { error in
//                // PowerStateはBool(NSNumber)でvalueが返ってくる
//                guard let value = powerState.value as? Bool else {
//                    return
//                }
//                // ライトが点灯中ならtrue
//                // ライトが消灯中ならfalse
//                print("# powerState: \(value)")
//            }
        }
    }
}

//更新完抓到所有的home
extension ViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
      
      for home1 in manager.homes {
        print ("(2)")
        print ("* read home:\(home1)")
        loadAccessories()
        print ("* accessories=\(accessories)")
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
