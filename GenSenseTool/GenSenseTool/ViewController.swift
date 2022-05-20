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
    @IBOutlet weak var pgProcess: UIProgressView!
    
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
    let saveAccessoryGroup = DispatchGroup()
    let removeActionGroup = DispatchGroup()
    var saveError: Error?
    //--
    var arrActionName = [String]()
    var arrData = [Dictionary<String, Any>]()
    var totalCount = 0
    //--
    var findcharacteristics = [HMCharacteristic?]()
    var findAccessorys = [HMAccessory]()
    var findHomes = [HMHome?]()
    
    let manufacturerKeyWord = "Fibargroup"      //就沒有中間o
    let modelKeyWord = "FibaroScene"
    
    //--Infomation
    @IBOutlet var  blurView:UIVisualEffectView!
    @IBOutlet var popView: PopView!
   
    // 建立一個Refresh Control，下拉更新資料使用
    var refreshControl: UIRefreshControl!
    

    
    @IBAction func doAction(_ sender: UIButton) {
        let buttonPosition = sender.convert(CGPoint(), to:tableView)
        let indexPath = tableView.indexPathForRow(at:buttonPosition)
        guard let row = indexPath?.row else { return }
        
        let home = arrData[row]["home"] as! HMHome
        
        let actionSetName = (arrData[row]["actionSet"] as! HMActionSet).name
        
        let acc = arrData[row]["acc"] as? HMAccessory

        guard let reachable = acc?.isReachable else {
            return
        }
        guard let id = acc?.uniqueIdentifier else {
            return
        }
        guard let roomname = acc?.room?.name else {
            return
        }
        popView.lbTitle.text = "Information"
        popView.lbTitle.font = UIFont(name: "Cubic 11", size: 30)
        popView.tvInfo.text =
        """
        Home Name : \(home.name)
        
        ActionSet Name : \(actionSetName)

        Accessory Name : \(acc!.name)
        
        - Reachable : \(reachable)
        
        - Identifer :
            \(id)
        
        - Room : \(roomname)
        """
        animateScaleIn(desiredView: blurView)
        animateScaleIn(desiredView: popView)
     }
    @IBAction func doneAction(_ sender: UIButton) {
        animateScaleOut(desiredView: popView)
        animateScaleOut(desiredView: blurView)
     }
    //--
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeManager.delegate = self
        tfOutput.text = ""
        tfOutput.isEditable = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        lbNoHad.isHidden = true
        self.tableView.separatorStyle = .none
        //--
        blurView.bounds = self.view.bounds
        popView.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width * 0.9, height:self.view.bounds.height * 0.4)
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadEventTableView), for: UIControl.Event.valueChanged)
        
        
//        let refreshImage = UIImageView()
//        refreshImage.image = UIImage(named: "img_redo")
//        refreshControl.backgroundColor = UIColor.clear
//        refreshControl.tintColor = UIColor.clear
//        refreshControl.addSubview(refreshImage)
//        refreshImage.frame = refreshControl.bounds.offsetBy(dx: self.view.frame.size.width / 2 - 20, dy: 10)
//        refreshImage.frame.size.width = 40 // Whatever width you want
//        refreshImage.frame.size.height = 40 // Whatever height you want
//                                    
//        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
//        rotateAnimation.fromValue = 0.0
//        rotateAnimation.toValue = CGFloat(.pi * 2.0)
//        rotateAnimation.duration = 1.0  // Change this to change how many seconds a rotation takes
//        rotateAnimation.repeatCount = Float.greatestFiniteMagnitude
//        refreshImage.layer.add(rotateAnimation, forKey: "rotate")
        
        tableView.addSubview(refreshControl)
        
    
    }
    
    @objc func reloadEventTableView() {
        // 移除array中的所有資料
        // Start animation here.
        
        arrData.removeAll()
          addHomes(homeManager.homes)
            totalCount = 0
            for home2 in homeManager.homes {
              print ("(22)")
              print ("* read home:\(home2)")
              genSense2(for: home2)
              print ("* findcharacteristics=\(findcharacteristics)")
            }
        tableView.reloadData()
//        self.refreshControl.subviews[1].layer.removeAnimation(forKey: "rotate")
        self.refreshControl.endRefreshing()
      

    }
    
    //---
    /// Animates a view to scale in and display
    func animateScaleIn(desiredView: UIView) {
        let backgroundView = self.view!
        backgroundView.addSubview(desiredView)
        desiredView.center = backgroundView.center
        desiredView.isHidden = false
        
        desiredView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        desiredView.alpha = 0
        
        UIView.animate(withDuration: 0.3) {
            desiredView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            desiredView.alpha = 1
//            desiredView.transform = CGAffineTransform.identity
        }
    }
    
    /// Animates a view to scale out remove from the display
    func animateScaleOut(desiredView: UIView) {
        UIView.animate(withDuration: 0.2, animations: {
            desiredView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            desiredView.alpha = 0
        }, completion: { (success: Bool) in
            desiredView.removeFromSuperview()
        })
        
        UIView.animate(withDuration: 0.2, animations: {
            
        }, completion: { _ in
            
        })
    }
    //---
    
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
    
    //以Accessorie去找
    func genSense2(for home: HMHome?) {
        //找出所有characteristics
        guard let homeAccessories = home?.accessories else {
          return
        }
        //把情境中所有的actionSet找出來建立一陣列列表
        getActionsArray(home:home!)
        for accessorie in homeAccessories {
            print ("*- accessorie :\(accessorie)")
            print ("*- accessorie name:\(accessorie.name)")
            print ("*- accessorie manufacturer:\(accessorie.manufacturer ?? "")")
            print ("*- accessorie model:\(accessorie.model ?? "")")
            //以Switch條件
            let accsChara = accessorie.find(serviceType: HMServiceTypeSwitch , characteristicType: HMCharacteristicMetadataFormatBool)
            print ("*- accs:\(accsChara)")
            print ("*- accessorie services:\(accessorie.services)")
            print ("*----")
            if accsChara != nil{
                //找尋特定關鍵定條件
                if accessorie.manufacturer == manufacturerKeyWord && accessorie.model == modelKeyWord
                {
                    if !arrActionName.contains(accessorie.name) {
                        findcharacteristics.append(accsChara)
                        findAccessorys.append(accessorie)
                        findHomes.append(home)
                        totalCount+=1
                    }
                }
            }
        }
        
        if let home = home {
            //我們要的Switch
                print ("-characteristics = \(findcharacteristics)")
                for  (i,chara) in findcharacteristics.enumerated() {
                    print ("**4 findAccessorys count:\(findAccessorys.count)")
                            let name = findAccessorys[i].name
                            print ("findAccessorys[\(i)]:\(name)")
                            let createSenseName = name
                            print ("createSenseName name:\(createSenseName)")
                            
                            //建立判別情境是否有的旗標
                            if arrActionName.contains(createSenseName) {
                                print("*** Sense: \(createSenseName) had. ***")
                            }else{
                                print("*** \(createSenseName) had not. ***")
                                saveActionSetGroup.enter()
                                if findHomes[i] == home {
                                    home.addActionSet(withName: createSenseName) { [self] actionSet, error in
                                        if let error = error {
                                            print("HomeKit: Error creating action set: \(error.localizedDescription)")
                                        }
                                        else {
                                            self.saveActionSet2(actionSet!, chara: chara!,acc: self.findAccessorys[i],home:home)
                                        }
                                        self.saveActionSetGroup.leave()
                                        self.tableView.reloadData()
                                    }
                                }
                            }
                }
        }
    }
    
    //以service去找
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
                      print ("*  chara.metadata?.manufacturerDescription = \(chara.metadata?.manufacturerDescription)")
                      
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
                                        if actionSet != nil {
                                            self.saveActionSet(actionSet!, chara: chara)
                                        }else{
                                            print ("* 空的actionSet不加")
                                        }
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
    
    func saveActionSet2(_ actionSet: HMActionSet, chara: HMCharacteristic,acc:HMAccessory,home:HMHome) {
        //這邊自己組裝
        let a = HMCharacteristicWriteAction(characteristic: chara, targetValue: 1 as NSCopying)

            saveActionSetGroup.enter()
            addAction(a, toActionSet: actionSet) { error in
                if let error = error {
                    print("HomeKit: Error adding action: \(error.localizedDescription)")
                    self.saveError = error
                }else{
                   
                    let createName = acc.name.replacingOccurrences(of: "00", with: "")
                        let ouputText = "Sense: \(createName) create ok. "
                        print (ouputText)
                        self.tfOutput.text += ouputText+"\n"
                        
                        self.arrData.append(["name":createName,"chars":chara,"actionSet":actionSet,"acc":acc
                                            ,"home":home])
                        print ("*arrData: \(self.arrData)")
                        
                        self.tableView.reloadData()
                  
                }
                self.saveActionSetGroup.leave()
                
//                self.saveActionSetGroup.notify(queue: DispatchQueue.main){
//                    self.tableView.reloadData()
//                }
            }
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
                }
            }
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
//    func tableView(_ tableView:UITableView,titileForHeaderInSection section: Int) -> String?{
//        return "1"
//        
//    }
//    
//    func numberOfSections(in tablView:UITableView) -> Int{
//        print ("* homes\(homes), \(homes.count)")
//        return homes.count
//    }
    
    func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath)
    {
    
        actionSet = arrData[indexPath.row]["actionSet"] as! HMActionSet
        print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lbNoHad.isHidden = arrData.count != 0
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
            
            if let home=arrData[indexPath.row]["home"] as? HMHome{
                print ("*home: \(home.name)")
                cell.lbHomeName.text = home.name
            }
            
            if let acc=arrData[indexPath.row]["acc"] as? HMAccessory{
               
                if let room = acc.room {
                    print ("*room name: \(room.name)")
                    cell.lbRoomName.text = room.name
                }
                }
//            cell.btnInfo.tag = indexPath.row
            
            
        }else{
            print ("out of array")
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        // action one
        let editAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
            print("Edit tapped")
            
            self.actionSet = self.arrData[indexPath.row]["actionSet"] as? HMActionSet
            print ("* self.actionSet = \(String(describing: self.actionSet)) actionSet = \(self.actionSet)")
            print ("* arrActionName =\(self.arrActionName)")
            
            let alert = UIAlertController(title: "Alert", message: "改名個直接對應的名子將會改變", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in
                
                let alertController = UIAlertController(title: "Scene Name rename to", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "請入要修改的名稱"
                    textField.text = self.arrData[indexPath.row]["name"] as? String
                    }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    if let textField = alertController.textFields?[0] {
                                if textField.text!.count > 0 {
                                    print("Text :: \(textField.text ?? "")")
                                    if textField.text != nil {
                                        self.updateNameIfNecessary2( textField.text! ,indexPath: indexPath,acc: self.arrData[indexPath.row]["acc"] as! HMAccessory)
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
            
        })
        editAction.backgroundColor = UIColor.blue

        // action two
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            print("Delete tapped")
            
            self.removeTargetValueForCharacteristic(self.arrData[indexPath.row]["home"] as! HMHome ,actionSet: self.arrData[indexPath.row]["actionSet"] as! HMActionSet,indexPath:indexPath, completion: {
              print ("done")
            })
         
                                                
        })
        deleteAction.backgroundColor = UIColor.red

        return [editAction, deleteAction]
    }
    
    //MARK: -
    func updateNameIfNecessary2(_ name: String,indexPath: IndexPath,acc:HMAccessory) {
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
                //upload Accessory
                self.updateName2(name, forAccessory: acc)
            }
            self.saveActionSetGroup.leave()
        }
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
    
    func updateName2(_ name: String, forAccessory accessory: HMAccessory) {
        saveAccessoryGroup.enter()
        accessory.updateName(name) { error in
            if let error = error {
//                self.displayError(error)
//                self.didEncounterError = true
                print ("err")
            }
            print ("ok")
            self.saveAccessoryGroup.leave()
        }
    }
    
    /*
    func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Rename"
    }
    
    
    /// Removes the action associated with the index path.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            actionSet = arrData[indexPath.row]["actionSet"] as! HMActionSet
    
            let alert = UIAlertController(title: "Alert", message: "改名個直接對應的名子將會改變", preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: {_ in
                
                let alertController = UIAlertController(title: "Scene Name rename to", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "請入要修改的名稱"
                    textField.text = self.arrData[indexPath.row]["name"] as? String
                    }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    if let textField = alertController.textFields?[0] {
                                if textField.text!.count > 0 {
                                    print("Text :: \(textField.text ?? "")")
                                    if textField.text != nil {
                                        self.updateNameIfNecessary2( textField.text! ,indexPath: indexPath,acc: self.arrData[indexPath.row]["acc"] as! HMAccessory)
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
    */
    
    func removeTargetValueForCharacteristic2(_ home: HMHome?,actionSet:HMActionSet?, completion: @escaping () -> Void) {
        /*
            We need to create a dispatch group here, because in many cases
            there will be one characteristic saved in the Action Set, and one
            in the target value map. We want to run the completion closure only one time,
            to ensure we've removed both.
        */
        let group = DispatchGroup()
    //    if targetValueMap.object(forKey: characteristic) != nil {
    //        // Remove the characteristic from the target value map.
    //        DispatchQueue.main.async(group: group) {
    //            self.targetValueMap.removeObject(forKey: characteristic)
    //        }
    //    }
        removeActionGroup.enter()
     
        print ("home1:\(home)")
        home!.removeActionSet(actionSet!) { error in
//            completionHandler(error)
//            self.updateActionSetSection()
            if error != nil {
                print ("home:\(home)")
            }else{
                print ("error")
                print(error?.localizedDescription)
                print ("home:\(home)")
            }
            self.removeActionGroup.leave()
        }
        group.notify(queue: DispatchQueue.main, execute: completion)
    }
    
    func removeTargetValueForCharacteristic(_ home: HMHome?,actionSet:HMActionSet?,indexPath:IndexPath, completion: @escaping () -> Void) {
        /*
            We need to create a dispatch group here, because in many cases
            there will be one characteristic saved in the Action Set, and one
            in the target value map. We want to run the completion closure only one time,
            to ensure we've removed both.
        */
        let group = DispatchGroup()
    //    if targetValueMap.object(forKey: characteristic) != nil {
    //        // Remove the characteristic from the target value map.
    //        DispatchQueue.main.async(group: group) {
    //            self.targetValueMap.removeObject(forKey: characteristic)
    //        }
    //    }
        removeActionGroup.enter()
     
        print ("home1:\(home)")
        home!.removeActionSet(actionSet!) { error in
//            completionHandler(error)
//            self.updateActionSetSection()
            if error != nil {
                print ("home:\(home)")
//                self.arrData.remove(at: indexPath.row)
//                self.tableView.deleteRows(at: [indexPath], with: .automatic)
            }else{
                print ("error")
                print(error?.localizedDescription)
                print ("home:\(home)")
            }
            self.removeActionGroup.leave()
           
        }
       
      
            self.arrData.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
   
        
//        if let actions = actionSet?.actions {
//            for case let action as HMCharacteristicWriteAction<CellValueType> in actions {
//                if action.characteristic == characteristic {
//                    /*
//                        Also remove the action, and only relinquish the dispatch group
//                        once the action set has finished.
//                    */
//                    group.enter()
//
//
//
//
//                    actionSet?.removeAction(action) { error in
//                        if let error = error {
//                            print(error.localizedDescription)
//                        }
//                        group.leave()
//                        //
//                        //
//
//                    }
//                }
//            }
//        }
        // Once we're positive both have finished, run the completion closure on the main queue.
//        group.notify(queue: DispatchQueue.main, execute: completion)
    }

}
//end


//    func tableView(_ tableView: UITableView, titleForHeaderInSection
//                                section: Int) -> String? {
//       return "已轉換出"
//    }
    //MARK: -
  

//更新完抓到所有的home
extension ViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
      totalCount = 0
      for home1 in manager.homes {
//        self.home = home1
        print ("(2)")
        print ("* read home:\(home1)")
        genSense2(for: home1)
        print ("* findcharacteristics=\(findcharacteristics)")
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

extension UIView{
    func rotate() {
        let rotation : CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = NSNumber(value: Double.pi * 2)
        rotation.duration = 1
        rotation.isCumulative = true
        rotation.repeatCount = Float.greatestFiniteMagnitude
        self.layer.add(rotation, forKey: "rotationAnimation")
    }
}
