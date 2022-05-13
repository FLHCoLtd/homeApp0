//
//  ViewController.swift
//  GenActiontool
//
//  Created by alex on 2022/5/6.
//
import UIKit
import HomeKit

typealias CellValueType = NSCopying

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    @IBOutlet weak var tfOutput: UITextView!
    @IBOutlet weak var btnOpenHomeApp: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lbNoHad: UILabel!
    
    var homes = [HMHome]()
    let homeManager = HMHomeManager()
    //--
    var home: HMHome? = nil
    var accessories = [HMAccessory]()
    //--
    var actionSet: HMActionSet?
    var aAction: HMAction?
    //--Sense
    let targetValueMap = NSMapTable<HMCharacteristic, CellValueType>.strongToStrongObjects()
    /// A dispatch group to wait for all of the individual components of the saving process.
    let saveActionSetGroup = DispatchGroup()
    var saveError: Error?
    //--
    var arrActionName = [String]()
    
    //--
    
    var arrData = [Dictionary<String, Any>]()
    var totalCount = 0

    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeManager.delegate = self
        tfOutput.text = ""
        tfOutput.isEditable = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        lbNoHad.isHidden = true
    }
    
    func addHomes(_ homes: [HMHome]) {
      self.homes.removeAll()
      for home in homes {
        self.homes.append(home)
      }
    }
    
    func getActionsArray(home:HMHome)
    {
        arrActionName = [String]()
        for findAction in home.actionSets
        {
            arrActionName.append(findAction.name)
        }
        print ("* arrActionName=\(arrActionName)")
    }
    
    func genSense(for home: HMHome?) {
        if let home = home {
            
            
            //把情境中所有的actionSet找出來建立一陣列列表
            getActionsArray(home:home)
            
            //找出需要轉換的總筆數
            if let _ = home.servicesWithTypes([HMServiceTypeSwitch]) {
              for serv in home.servicesWithTypes([HMServiceTypeSwitch])! {
                  print ("*serv = \(serv)")
                  let characteristics = serv.characteristics
                  print ("-characteristics = \(characteristics)")
                  for chara in characteristics {
                      if let value = chara.value, let name = chara.service?.name
                          ,let format = chara.metadata?.format , let desc=chara.metadata?.manufacturerDescription{
                          if  desc == "Power State" && name.hasPrefix("00") && name.hasSuffix("00") {
                              let createSenseName = name.replacingOccurrences(of: "00", with: "")
                              if !arrActionName.contains(createSenseName) {
                                  totalCount+=1
                              }
                             }
                      }
                  }
              }
            }
            print ("*totalCount=\(totalCount)")
            if totalCount == 0 {
                lbNoHad.isHidden = false
            }
            
            //找 Switch
            if let _ = home.servicesWithTypes([HMServiceTypeSwitch]) {
            printDebug(output: "=== \(home.name) ===")
            for serv in home.servicesWithTypes([HMServiceTypeSwitch])! {
                print ("*serv = \(serv)")
                let characteristics = serv.characteristics
                print ("-characteristics = \(characteristics)")
                for chara in characteristics {
                    if let value = chara.value, let name = chara.service?.name
                        ,let format = chara.metadata?.format , let desc=chara.metadata?.manufacturerDescription{
                        
                            //找"Powe State" (switch) 前後綴為都 00
                        if  desc == "Power State" && name.hasPrefix("00") && name.hasSuffix("00") {
                            
                            print (" - chara.metadata?.format=\(format)")
//                            print (" - chara.service.name=\(name)")
                            print (" - chara.value=\(value)")
                            print (" - chara.metadata?.description=\(desc)")
                            print ("---")
                            
                            print ("chara.service.name name:\(name)")
                            let createSenseName = name.replacingOccurrences(of: "00", with: "")
                            print ("createSenseName name:\(createSenseName)")
                            
                            //建立判別情境是否有的旗標
                            if arrActionName.contains(createSenseName) {
                                printDebug(output: "*** Sense: \(createSenseName) had. ***")
                            }else{
//                                printDebug(output: "*** \(createSenseName) had not. ***")
                                print("*** \(createSenseName) had not. ***")
                                saveActionSetGroup.enter()
                                home.addActionSet(withName: createSenseName) { actionSet, error in
                                    if let error = error {
                                        print("HomeKit: Error creating action set: \(error.localizedDescription)")
                                    }
                                    else {
                                        self.saveActionSet(actionSet!, chara: chara)
                                    }
                                    self.saveActionSetGroup.leave()
//                                    self.tableView.reloadData()
                                }
                            }
                            
                        }

                    }
                    
                }
                print ("===")
              
            }
            }else{
//                printDebug(output: "=== \(home.name)===\n *** 下沒有switch *** ")
                  print("=== \(home.name)===\n *** 下沒有switch *** ")
            }
        }
    }
    
    func printDebug(output:String)
    {
        print (output)
        tfOutput.text += output+"\n"
    }
    /**
        Searches through the target value map and existing `HMCharacteristicWriteActions`
        to find the target value for the characteristic in question.
        
        - parameter characteristic: The characteristic in question.
        
        - returns:  The target value for this characteristic, or nil if there is no target.
    */
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
                    if let name=chara.service?.name {
                        let createName = name.replacingOccurrences(of: "00", with: "")
                        let ouputText = "Sense: \(createName) create ok. "
                        print (ouputText)
                        self.tfOutput.text += ouputText+"\n"
                        
                        self.arrData.append(["name":createName,"chars":chara,"actionSet":actionSet])
                        print ("*arrData: \(self.arrData)")
                        
                        self.totalCount -= 1
                        print ("*totalCount: \(self.totalCount)")
                        if self.totalCount==0 {
//                            self.tableView.reloadData()
                        }
                        
                    }
                }
                self.saveActionSetGroup.leave()
                
                self.saveActionSetGroup.notify(queue: DispatchQueue.main){
                    self.tableView.reloadData()
                    print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
//                    self.actionSet = actionSet
                    print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
                }
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
 
    @IBAction func openHomeApp(_ sender: UIButton) {
          let url = URL(string: "com.apple.home://launch")!
          UIApplication.shared.open(url)
     }
    
    //MARK: - tableview
    func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath)
    {
        actionSet = arrData[indexPath.row]["actionSet"] as! HMActionSet
        print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SenseTableViewCell
        print ("* indexPath.row:\(indexPath.row)")
        let isIndexValid = arrData.indices.contains(indexPath.row)
        if isIndexValid{
            if let name=arrData[indexPath.row]["name"]{
                cell.lbSenseName.text = name as! String
            }
        }else{
            print ("out of array")
        }
        return cell
    }
    
    
    func updateNameIfNecessary(_ name: String,indexPath: IndexPath) {
        saveActionSetGroup.enter()
        print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
        actionSet?.updateName(name) { error in
            if let error = error {
                let perr = "HomeKit: Error updating name: \(error.localizedDescription)"
                print(perr)
                let alert = UIAlertController(title: "Alert", message: perr, preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                self.saveError = error
            }else{
                self.arrData[indexPath.row]["name"]=name
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            }
            self.saveActionSetGroup.leave()
         
            
            
        }
    }
    
//    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
//
//        // action one
//        let editAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
//            print("Edit tapped")
//        })
//        editAction.backgroundColor = UIColor.blue
//
//        // action two
//        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
//            print("Delete tapped")
//        })
//        deleteAction.backgroundColor = UIColor.red
//
//        return [editAction, deleteAction]
//    }
    
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Rename"
    }
    
    /// Removes the action associated with the index path.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //把情境中所有的actionSet找出來建立一陣列列表
//            if home != nil {
//                getActionsArray(home: self.home!)
//            }
            actionSet = arrData[indexPath.row]["actionSet"] as! HMActionSet
            print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
            print ("* arrActionName =\(arrActionName)")
            
            
            let alert = UIAlertController(title: "Alert", message: "改名不要再執行此工具，不然會有多個情境對一個按鈕Switch", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in 
                
                let alertController = UIAlertController(title: "Scene Name rename to", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "請入要修改的名稱"
                    }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    if let textField = alertController.textFields?[0] {
                                if textField.text!.count > 0 {
                                    print("Text :: \(textField.text ?? "")")
                                    if textField.text != nil {
                                        self.updateNameIfNecessary( textField.text! ,indexPath: indexPath)
                                    }
                                }
                            }
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                        (action : UIAlertAction!) -> Void in })
                
                    alertController.addAction(saveAction)
                    alertController.addAction(cancelAction)
                
                self.present(alertController, animated: true, completion: nil)
                
            }))
            self.present(alert, animated: true, completion: nil)
            

                         
         }
        }
    }
    


    /**
        First removes the characteristic from the `targetValueMap`.
        Then removes any `HMCharacteristicWriteAction`s from the action set
        which set the specified characteristic.
        
        - parameter characteristic: The `HMCharacteristic` to remove.
        - parameter completion: The closure to invoke when the characteristic has been removed.
    */
    func removeTargetValueForCharacteristic(_ characteristic: HMCharacteristic, completion: @escaping () -> Void) {
        /*
            We need to create a dispatch group here, because in many cases
            there will be one characteristic saved in the Action Set, and one
            in the target value map. We want to run the completion closure only one time,
            to ensure we've removed both.
        */
//        let group = DispatchGroup()
//        if targetValueMap.object(forKey: characteristic) != nil {
//            // Remove the characteristic from the target value map.
//            DispatchQueue.main.async(group: group) {
//                self.targetValueMap.removeObject(forKey: characteristic)
//            }
//        }
     

           

    }
//    func tableView(_ tableView: UITableView, titleForHeaderInSection
//                                section: Int) -> String? {
//       return "已轉換出"
//    }
    //MARK: -
    






//更新完抓到所有的home
extension ViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
      for home1 in manager.homes {
        print ("(2)")
        print ("* read home:\(home1)")
        genSense(for: home1)
      }
  }
}

//--
extension ViewController: HMAccessoryDelegate {
  func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
  }
}

extension ViewController: HMAccessoryBrowserDelegate {
  func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
//      discoveredAccessories.append(accessory)
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
