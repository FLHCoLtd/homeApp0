//
//  ViewController.swift
//  GenActiontool
//
//  Created by alex on 2022/5/6.
//
import UIKit
import HomeKit

typealias CellValueType = NSCopying

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchResultsUpdating, UISearchBarDelegate  {
    
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
    
    var filterDataList = [Dictionary<String, Any>]()
    var searchedDataSource = [Dictionary<String, Any>]()
    
    var searchController: UISearchController!
    var isShowSearchResult: Bool = false // 是否顯示搜尋的結果
    
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
    var badgeNumber = 0

    
    @IBAction func doAction(_ sender: UIButton) {
        searchController.searchBar.resignFirstResponder()
        searchController.isActive = false
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
        searchController.isActive = true
     }
    //--

//    override func viewDidDisappear(_ animated: Bool) {
//                   if searchController.isActive == true {
//                       searchController.isActive = false
//                    }
//             }
    
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

        tableView.addSubview(refreshControl)
        
        
        // 生成SearchController
        self.searchController = UISearchController(searchResultsController: nil)
        self.searchController.searchBar.placeholder = "請輸入情境名稱"
        self.searchController.searchBar.sizeToFit()
        self.searchController.searchResultsUpdater = self // 遵守UISearchResultsUpdating協議
        self.searchController.searchBar.delegate = self // 遵守UISearchBarDelegate協議
        self.searchController.dimsBackgroundDuringPresentation = false // 預設為true，若是沒改為false，則在搜尋時整個TableView的背景顏色會變成灰底的
        
        // 將searchBar掛載到tableView上
        self.tableView.tableHeaderView = self.searchController.searchBar
        self.tableView.tableHeaderView?.isHidden = true

    }

    
    let badgeSize: CGFloat = 20
    let badgeTag = 9830384

    func badgeLabel(withCount count: Int) -> UILabel {
        let badgeCount = UILabel(frame: CGRect(x: 0, y: 0, width: badgeSize, height: badgeSize))
        badgeCount.translatesAutoresizingMaskIntoConstraints = false
        badgeCount.tag = badgeTag
        badgeCount.layer.cornerRadius = badgeCount.bounds.size.height / 2
        badgeCount.textAlignment = .center
        badgeCount.layer.masksToBounds = true
        badgeCount.textColor = .white
        badgeCount.font = badgeCount.font.withSize(12)
        badgeCount.backgroundColor = .systemRed
        badgeCount.text = String(count)
        return badgeCount
    }
    
    func showBadge(withCount count: Int) {
        if count > 0 {
        let badge = badgeLabel(withCount: count)
            btnOpenHomeApp.addSubview(badge)
            NSLayoutConstraint.activate([
                badge.leftAnchor.constraint(equalTo: btnOpenHomeApp.leftAnchor, constant: 22),
                badge.topAnchor.constraint(equalTo: btnOpenHomeApp.topAnchor, constant: 18),
                badge.widthAnchor.constraint(equalToConstant: badgeSize),
                badge.heightAnchor.constraint(equalToConstant: badgeSize)
            ])
            self.view.layoutIfNeeded()
        }
    }

    func clearBadge()
    {
        badgeNumber = 0
        if badgeNumber == 0 {
            if let badge = btnOpenHomeApp.viewWithTag(badgeTag) {
                   badge.removeFromSuperview()
               }
        }else {
            showBadge(withCount: badgeNumber)
            
        }
    }
    
    @objc func reloadEventTableView() {
        arrData.removeAll()
          addHomes(homeManager.homes)
            totalCount = 0
            for home2 in homeManager.homes {
              clearBadge()
              print ("(22)")
              print ("* read home:\(home2)")
              genSense2(for: home2)
              print ("* findcharacteristics=\(findcharacteristics)")
            }
        tableView.reloadData()
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
                    
                    self.searchedDataSource = self.arrData
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
    
//    // Create a standard footer that includes the returned text.
//    func tableView(_ tableView: UITableView, titleForFooterInSection
//                                section: Int) -> String? {
//        if arrData.count > 0 {
//            return "已創建 \(arrData.count)筆"
//        }else{
//            return ""
//        }
//    }
    
    func tableView(_ tableView: UITableView,didSelectRowAt indexPath: IndexPath)
       {
          
           if isShowSearchResult{
               actionSet = filterDataList[indexPath.row]["actionSet"] as! HMActionSet
                   print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
               let exehome = filterDataList[indexPath.row]["home"] as! HMHome
               let chara = filterDataList[indexPath.row]["chars"] as! HMCharacteristic
               let acc = filterDataList[indexPath.row]["acc"] as! HMAccessory
               executeActionSet(actionSet!,home: exehome)
               if actionSet!.isExecuting {
                    print ("* isExecting")
                   popView.lbTitle.text = actionSet?.name
                   popView.tvInfo.text = "已情境在執行中...\n不重覆用執行!"
                   popView.tvInfo.font = UIFont(name: "Cubic 11", size: 32)
                   animateScaleIn(desiredView: blurView)
                   animateScaleIn(desiredView: popView)
               }
           }else{
               actionSet = arrData[indexPath.row]["actionSet"] as! HMActionSet
                   print ("* self.actionSet = \(self.actionSet) actionSet = \(actionSet)")
               let exehome = arrData[indexPath.row]["home"] as! HMHome
               let chara = arrData[indexPath.row]["chars"] as! HMCharacteristic
               let acc = arrData[indexPath.row]["acc"] as! HMAccessory
               executeActionSet(actionSet!,home: exehome)
               if actionSet!.isExecuting {
                    print ("* isExecting")
                   popView.lbTitle.text = actionSet?.name
                   popView.tvInfo.text = "已情境在執行中...\n不重覆用執行!"
                   popView.tvInfo.font = UIFont(name: "Cubic 11", size: 32)
                   animateScaleIn(desiredView: blurView)
                   animateScaleIn(desiredView: popView)
               }
           }
       }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        lbNoHad.isHidden = arrData.count != 0
        searchController.searchBar.isHidden = !lbNoHad.isHidden
        
        if badgeNumber>0 {
            lbNoHad.text = ""
        }
        
        if arrData.count > 0{
            tableView.tableHeaderView?.isHidden = false
            tfOutput.isHidden = false
            tfOutput.text = "創建了共\(arrData.count)組情境"
        }else{
            tfOutput.isHidden = true
        }
        
        if self.isShowSearchResult {
            // 若是有查詢結果則顯示查詢結果集合裡的資料
            return self.filterDataList.count
        } else {
            return arrData.count
        }
        
    
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SenseTableViewCell
        print ("* indexPath.row:\(indexPath.row)")
        
        
        if self.isShowSearchResult {
            // 若是有查詢結果則顯示查詢結果集合裡的資料
            let isIndexValid = filterDataList.indices.contains(indexPath.row)
            if isIndexValid{
                if let name=filterDataList[indexPath.row]["name"]{
                    cell.lbSenseName.text = name as! String
                }
                if let home=filterDataList[indexPath.row]["home"] as? HMHome{
                    print ("*home: \(home.name)")
                    cell.lbHomeName.text = home.name
                }
                
                if let acc=filterDataList[indexPath.row]["acc"] as? HMAccessory{
                   
                    if let room = acc.room {
                        print ("*room name: \(room.name)")
                        cell.lbRoomName.text = room.name
                    }
                    }
                }else{
                    print ("out of array")
                }
        } else {
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
                }else{
                    print ("out of array")
                }
        }
        
        
      
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {

        
       
        
        // action one
        let editAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
            print("Edit tapped")
            
            if self.isShowSearchResult {
                self.actionSet = self.filterDataList[indexPath.row]["actionSet"] as? HMActionSet
                print ("* self.actionSet = \(String(describing: self.actionSet)) actionSet = \(self.actionSet)")
            }else{
                self.actionSet = self.arrData[indexPath.row]["actionSet"] as? HMActionSet
                print ("* self.actionSet = \(String(describing: self.actionSet)) actionSet = \(self.actionSet)")
            }

            
            print ("* arrActionName =\(self.arrActionName)")
                let alertController = UIAlertController(title: "Scene Name rename to", message: "", preferredStyle: UIAlertController.Style.alert)
                alertController.addTextField { (textField : UITextField!) -> Void in
                    textField.placeholder = "請入要修改的名稱"
                        if self.isShowSearchResult {
                            textField.text = self.filterDataList[indexPath.row]["name"] as? String
                        }else{
                            textField.text = self.arrData[indexPath.row]["name"] as? String
                        }
                    }
                let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { alert -> Void in
                    if let textField = alertController.textFields?[0] {
                                if textField.text!.count > 0 {
                                    print("Text :: \(textField.text ?? "")")
                                    if textField.text != nil {
                                        if self.isShowSearchResult {
                                            self.updateNameIfNecessary2( textField.text! ,indexPath: indexPath,acc: self.filterDataList[indexPath.row]["acc"] as! HMAccessory)
                                        }else{
                                        self.updateNameIfNecessary2( textField.text! ,indexPath: indexPath,acc: self.arrData[indexPath.row]["acc"] as! HMAccessory)
                                        }
                                    }
                                }
                            }
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                        (action : UIAlertAction!) -> Void in })
                
                    alertController.addAction(saveAction)
                    alertController.addAction(cancelAction)
                
//                self.present(alertController, animated: true, completion: nil)
            
            if self.presentedViewController==nil{
                self.present(alertController, animated: true, completion: nil)
            }else{
                self.presentedViewController!.present(alertController, animated: true, completion: nil)
            }
            
            
        })
        editAction.backgroundColor = UIColor.blue

        // action two
        let deleteAction = UITableViewRowAction(style: .default, title: "Delete", handler: { (action, indexPath) in
            print("Delete tapped")
            
            
            if self.isShowSearchResult {
                self.actionSet = self.filterDataList[indexPath.row]["actionSet"] as? HMActionSet
                print ("* self.actionSet = \(String(describing: self.actionSet)) actionSet = \(self.actionSet)")
            }else{
                self.actionSet = self.arrData[indexPath.row]["actionSet"] as? HMActionSet
                print ("* self.actionSet = \(String(describing: self.actionSet)) actionSet = \(self.actionSet)")
            }

            
            if self.isShowSearchResult {
                // 若是有查詢結果則顯示查詢結果集合裡的資料
                self.removeTargetValueForCharacteristic(self.filterDataList[indexPath.row]["home"] as! HMHome ,actionSet: self.filterDataList[indexPath.row]["actionSet"] as! HMActionSet,indexPath:indexPath, completion: {
                  print ("done")
                })
            } else {
                self.removeTargetValueForCharacteristic(self.arrData[indexPath.row]["home"] as! HMHome ,actionSet: self.arrData[indexPath.row]["actionSet"] as! HMActionSet,indexPath:indexPath, completion: {
                  print ("done")
                })
            }
            
            
           
         
                                                
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
                if self.isShowSearchResult{
                    
                    for (i,arrSync) in self.arrData.enumerated(){
                        if arrSync["name"] as! String == self.filterDataList[indexPath.row]["name"] as! String {
                            self.arrData[i]["name"] = name
                        }
                    }
                    
                    self.filterDataList[indexPath.row]["name"]=name
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    //upload Accessory
                    self.updateName2(name, forAccessory: acc)
                    

                }else{
                    self.arrData[indexPath.row]["name"]=name
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    //upload Accessory
                    self.updateName2(name, forAccessory: acc)
                }
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
        
            badgeNumber+=1
            showBadge(withCount: badgeNumber)
        if isShowSearchResult{
            
            for (i,arrSync) in self.arrData.enumerated(){
                if arrSync["name"] as! String == self.filterDataList[indexPath.row]["name"] as! String {
                    self.arrData.remove(at: i)
                }
            }
            
            self.filterDataList.remove(at: indexPath.row)
        }else{
            self.arrData.remove(at: indexPath.row)
        }
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
   
    }

    func executeActionSet(_ actionSet: HMActionSet,home:HMHome) {
        if actionSet.actions.isEmpty {
            let alertTitle = NSLocalizedString("Empty Scene", comment: "Empty Scene")

            let alertMessage = NSLocalizedString("This scene is empty. To set this scene, first add some actions to it.", comment: "Empty Scene Description")
            
          //  displayMessage(alertTitle, message: alertMessage)
            
            return
        }
        let exehome = home
        
        exehome.executeActionSet(actionSet) { error in
            guard let error = error else { return }
            print (error)
           // self.displayError(error)
        }
    }
    
    // MARK: - Search Bar Delegate
    // ---------------------------------------------------------------------
    // 當在searchBar上開始輸入文字時
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        // 法蘭克選擇不需實作，因有遵守UISearchResultsUpdating協議的話，則輸入文字的當下即會觸發updateSearchResults，所以等同於同一件事做了兩次(可依個人需求決定，也不一定要跟法蘭克一樣選擇不實作)
    }
    
    // 點擊searchBar上的取消按鈕
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // 依個人需求決定如何實作
        // ...

    }
    
    // 點擊searchBar的搜尋按鈕時
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // 法蘭克選擇不需要執行查詢的動作，因在「輸入文字時」即會觸發 updateSearchResults 的 delegate 做查詢的動作(可依個人需求決定如何實作)
        // 關閉瑩幕小鍵盤
        self.searchController.searchBar.resignFirstResponder()
    }
    
    // MARK: - Search Controller Delegate
    // ---------------------------------------------------------------------
    // 當在searchBar上開始輸入文字時
    // 當「準備要在searchBar輸入文字時」、「輸入文字時」、「取消時」三個事件都會觸發該delegate
    func updateSearchResults(for searchController: UISearchController) {
        // 若是沒有輸入任何文字或輸入空白則直接返回不做搜尋的動作
        print ("* self.searchController.searchBar.text? =\(String(describing: self.searchController.searchBar.text))")
        
        print ("* arrData:\(self.arrData)")
        
        if self.searchController.searchBar.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count == 0 {
            filterDataList.removeAll()
            isShowSearchResult = false
            tableView.reloadData()
            return
        }
        tfOutput.text = ""
        self.filterDataSource()
    }
    
    // 過濾被搜陣列裡的資料
    func filterDataSource() {
        // 使用高階函數來過濾掉陣列裡的資料
        print ("* 3\(arrData) = \(searchedDataSource)")
        self.filterDataList = arrData.filter({ (item) -> Bool in
            return (item["name"] as! String).lowercased().range(of: self.searchController.searchBar.text!.lowercased()) != nil
        })
        
        if self.filterDataList.count > 0 {
            self.isShowSearchResult = true
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.init(rawValue: 1)! // 顯示TableView的格線
                    //tableView.reloadData()
        } else {
            self.tableView.separatorStyle = UITableViewCell.SeparatorStyle.none // 移除TableView的格線
            // 可加入一個查找不到的資料的label來告知使用者查不到資料...
            // ...
        }
        
        self.tableView.reloadData()
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
      badgeNumber = 0
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
