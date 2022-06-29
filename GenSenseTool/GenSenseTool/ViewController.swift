//
//  ViewController.swift
//  GenActiontool
//
//  Created by alex on 2022/5/6.
//
import UIKit
import HomeKit
import PickerPopupDialog
import MarqueeLabel
typealias CellValueType = NSCopying

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchResultsUpdating, UISearchBarDelegate, UIGestureRecognizerDelegate,HMHomeDelegate  {
    
    @IBOutlet weak var lbTitle: UILabel!
    @IBOutlet weak var tfOutput: UITextView!
    @IBOutlet weak var btnOpenHomeApp: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lbNoHad: UILabel!
    @IBOutlet weak var pgProcess: UIProgressView!
    
    var homes = [HMHome]()
    let homeManager = HMHomeManager()
    //--
    var home: HMHome?
    var accessories = [HMAccessory]()
    //--
    var actionSet: HMActionSet?
    var aAction: HMAction?
    //--Sense
    let targetValueMap = NSMapTable<HMCharacteristic, CellValueType>.strongToStrongObjects()
    /// A dispatch group to wait for all of the individual components of the saving process.
    let newRoomSetGroup = DispatchGroup()
    let saveActionSetGroup = DispatchGroup()
    let saveAccessoryGroup = DispatchGroup()
    let removeActionGroup = DispatchGroup()
    var saveError: Error?
    ///--
    var arrActionName = [String]()
    var arrActionSet = [HMActionSet]()
    
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
    
    //Keyword
    let manufacturerKeyWord = "Fibaro Scene"
    let modelKeyWord = "Fibaro Scene"
    
    //--Infomation
    @IBOutlet var  blurView:UIVisualEffectView!
    @IBOutlet var popView: PopView!
   
    // 建立一個Refresh Control，下拉更新資料使用
    var refreshControl: UIRefreshControl!
    var badgeNumber = 0

    // 房間PickerView
    let pickerView = PickerPopupDialog()
    var arrayPickerDataSource = [(Any, String)]()
    var arrHomePickerDataSource = [(Any, String)]()

    //Show Information
    @IBAction func doAction(_ sender: UIButton) {
        self.searchController.searchBar.resignFirstResponder()
        let buttonPosition = sender.convert(CGPoint(), to:tableView)
        let indexPath = tableView.indexPathForRow(at:buttonPosition)
        guard let row = indexPath?.row else { return }
    
        var infoHome:HMHome?
        var actionSetName = ""
        var acc:HMAccessory?
        //also
        if self.isShowSearchResult{
            infoHome = filterDataList[row]["home"] as? HMHome
            actionSetName = (filterDataList[row]["actionSet"] as! HMActionSet).name
            acc = filterDataList[row]["acc"] as? HMAccessory
        }else{
            infoHome = arrData[row]["home"] as? HMHome
            actionSetName = (arrData[row]["actionSet"] as! HMActionSet).name
            acc = arrData[row]["acc"] as? HMAccessory
        }
      
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
        popView.lbTitle.font = UIFont(name: "Cubic 11", size: 20)
        popView.tvInfo.font = UIFont(name: "System", size: 16)
        popView.tvInfo.text =
        """
        Home Name : \(home!.name)
        
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
    
    override  func viewDidAppear(_ animated: Bool) {
           super.viewDidAppear(animated)
           MarqueeLabel.controllerViewDidAppear(self)
       }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        homeManager.delegate = self
        tfOutput.text = ""
        tfOutput.isEditable = false
        self.tableView.delegate = self
        self.tableView.dataSource = self
        lbNoHad.isHidden = true
        self.tableView.separatorStyle = .none
        
        //popView
        blurView.bounds = self.view.bounds
        popView.bounds = CGRect(x: 0, y: 0, width: self.view.bounds.width * 0.9, height:self.view.bounds.height * 0.4)
       
        //產生RefreshControl
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(deletereloadEventTableView), for: UIControl.Event.valueChanged)
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
        
        //
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapChangeHome))
        lbTitle.isUserInteractionEnabled = true
        lbTitle.addGestureRecognizer(tap)
        
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
    
    //清除泡泡數字
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
    
    //清除變數
    func clearVar(){
        homes.removeAll()
        arrData.removeAll()
        filterDataList.removeAll()
        arrActionSet.removeAll()
        findcharacteristics.removeAll()     //must
        findAccessorys.removeAll()
        findHomes.removeAll()
        totalCount = 0
    }
    
    //刪除來的原來的已有的重覆情境後，等在重新建立產生
    @objc func deletereloadEventTableView() {
        print("* deletereloadEventTableView")
        clearVar()
        addHomes(homeManager.homes)
        let cast = ["(All)", "Generate Scene Tool"]         //check status unset String
        let checkTitlehadAll = cast.contains(lbTitle.text!)
        if (selectedHome == nil) && checkTitlehadAll {
            print ("* 未選指定特定家:\(selectedHome)")
            for homeUpdate in homeManager.homes {
              clearBadge()
              print ("* homeUpdate read home:\(homeUpdate)")
              updateSense(for: homeUpdate)
            }
        }else{
            print ("* 有選指定特定家:\(selectedHome!.name)")
            clearBadge()
            print ("* homeUpdate read home:\(selectedHome)")
            updateSense(for: selectedHome)
        }
        
//        tableView.reloadData()    //not need
        self.refreshControl.endRefreshing()
    }
    
    //只reload不刪除來的重覆的情境
    @objc func reloadEventTableView() {
        print ("** reloadEventTableView")
        clearVar()
        addHomes(homeManager.homes)
        let cast = ["(All)", "Generate Scene Tool"]         //check status unset String
        let checkTitlehadAll = cast.contains(lbTitle.text!)
        if (selectedHome == nil) && checkTitlehadAll {
            print ("* 未選指定特定家:\(selectedHome)")
            for homeUpdate in homeManager.homes {
              clearBadge()
              print ("* homeUpdate read home:\(homeUpdate)")
                genSense2(for: homeUpdate)
            }
        }else{
            print ("* 有選指定特定家:\(selectedHome!.name)")
            clearBadge()
            print ("* homeUpdate read home:\(selectedHome)")
            genSense2(for: selectedHome)
        }
        
//      tableView.reloadData()   //not need
        self.refreshControl.endRefreshing()
    }
    
    //---
    /// Animates a view to scale in and display
    func animateScaleIn(desiredView: UIView) {
        searchController.searchBar.isHidden = true
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
        searchController.searchBar.isHidden = false
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
    
    //MARK -  Home
    func addHomes(_ homes: [HMHome]) {
      self.homes.removeAll()
      for home in homes {
        self.homes.append(home)
      }
    }
    
    func getActionsArray(home:HMHome)
    {
        //                                   var roomNames=[String]()
        //                                   for room in home.rooms
        //                                   {
        //                                       roomNames.append(room.name)
        //                                   }
        arrActionName = [String]()
        arrActionSet = [HMActionSet]()
        for findAction in home.actionSets
        {
            arrActionName.append(findAction.name)
            arrActionSet.append(findAction)
        }
        print ("* home=\(home.name) ,arrActionName=\(arrActionName)")
    }
    
    
    
    //以Accessorie去找: Update
    func updateSense(for home: HMHome?) {
//        self.home = home
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
            print ("*-   accessorie.model:\(accessorie.model)")
          
            print ("*----")
            if accsChara != nil{
                //找尋特定關鍵定條件
                if accessorie.manufacturer == manufacturerKeyWord && accessorie.model == modelKeyWord
                {
//                    if !arrActionName.contains(accessorie.name) {
                        findcharacteristics.append(accsChara)
                        findAccessorys.append(accessorie)
                        findHomes.append(home)
                        totalCount+=1
//                    }
                }
            }
        }
       
        totalCount = findAccessorys.count

        if let home = home {
            //我們要的Switch
                print ("-characteristics = \(findcharacteristics)")
                for  (i,chara) in findcharacteristics.enumerated() {
                    let accessoryName = findAccessorys[i].name
                    var createSenseName = accessoryName

                            //建立判別情境是否有的旗標
                            if arrActionName.contains(createSenseName) {
                                print("*** Sense: \(createSenseName) had. ***")
                                print("*** arrActionSet: \(arrActionSet) had. ***")
                                for actionset in arrActionSet {
                                    print ("*** \(actionset.name) == \(createSenseName)")
                                    if actionset.name == createSenseName
                                    {
                                        //update
                                        self.saveActionSetUpdate(actionset, chara: chara!,acc: self.findAccessorys[i],home:home)
                                        print("*** arrActionSet: \(arrActionSet) update. ***")
                                    }
                                }

                            }else{
                                print("*** \(createSenseName) had not. ***")
                                
                                saveActionSetGroup.enter()
                                if findHomes[i] == home {
                                   var foundRoomPattern = false
                                   var retrimString = ""
                                   for selectroom in home.rooms
                                   {
                                       retrimString=selectroom.name
                                       //Match  XXXROOM Pattern 找有同房間的關鍵字
                                       if accessoryName.contains(selectroom.name+" ")
                                       {
                                           // Accessory裝置設定到指定房間中
                                           self.saveAccessoryGroup.enter()
                                           findHomes[i]!.assignAccessory(findAccessorys[i], to: selectroom) { error in
                                               if let error = error {
                                                     print ("error: \(error)")
                                   //                self.displayError(error)
                                   //                self.didEncounterError = true
                                               }
                                               self.saveAccessoryGroup.leave()
                                           }
                                           self.saveAccessoryGroup.notify(queue: DispatchQueue.main){
                                            //
                                           }
                                           foundRoomPattern=true
                                         break
                                       }
                                       
                                   }
                                    
                                    // Accessory裝置改名
                                    if foundRoomPattern {
                                        createSenseName = accessoryName.replacingOccurrences(of:retrimString+" ", with: "")
                                        self.updateName2(createSenseName, forAccessory: self.findAccessorys[i])
                                    }

                                    // 建立相對應情境
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
    
    
    //以Accessorie去找
    func genSense2(for home: HMHome?) {
//        self.home = home

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
            print ("*-   accessorie.model:\(accessorie.model)")
          
            print ("*----")
            if accsChara != nil{
                //找尋特定關鍵定條件
                if accessorie.manufacturer == manufacturerKeyWord && accessorie.model == modelKeyWord
                {
                    if !arrActionName.contains(accessorie.name) {
                        findcharacteristics.append(accsChara)
                        findAccessorys.append(accessorie)
                        findHomes.append(home)
//                        totalCount+=1
                    }
                }
            }
        }
        
        totalCount = findAccessorys.count
        
        if let home = home {
            //我們要的Switch
                print ("-characteristics = \(findcharacteristics)")
                for  (i,chara) in findcharacteristics.enumerated() {
                    let accessoryName = findAccessorys[i].name
                    var createSenseName = accessoryName

                            //建立判別情境是否有的旗標
                            if arrActionName.contains(createSenseName) {
                                print("*** Sense: \(createSenseName) had. ***")
                            }else{
                                print("*** \(createSenseName) had not. ***")
                                
                                saveActionSetGroup.enter()
                                if findHomes[i] == home {
                                   var foundRoomPattern = false
                                   var retrimString = ""
                                   for selectroom in home.rooms
                                   {
                                       retrimString=selectroom.name
                                       //Match  XXXROOM Pattern 找有同房間的關鍵字
                                       if accessoryName.contains(selectroom.name+" ")   
                                       {
                                           // Accessory裝置設定到指定房間中
                                           self.saveAccessoryGroup.enter()
                                           findHomes[i]!.assignAccessory(findAccessorys[i], to: selectroom) { error in
                                               if let error = error {
                                                     print ("error: \(error)")
                                   //                self.displayError(error)
                                   //                self.didEncounterError = true
                                               }
                                               self.saveAccessoryGroup.leave()
                                           }
                                           self.saveAccessoryGroup.notify(queue: DispatchQueue.main){
                                            //
                                           }
                                           foundRoomPattern=true
                                         break
                                       }
                                       
                                   }
                                    
                                    // Accessory裝置改名
                                    if foundRoomPattern {
                                        createSenseName = accessoryName.replacingOccurrences(of:retrimString+" ", with: "")
                                        self.updateName2(createSenseName, forAccessory: self.findAccessorys[i])
                                    }

                                    // 建立相對應情境
                                    home.addActionSet(withName: createSenseName) { [self] actionSet, error in
                                        if let error = error {
                                            print("HomeKit: Error creating action set: \(error.localizedDescription)")
                                        }
                                        else {
                                            self.saveActionSet2(actionSet!, chara: chara!,acc: self.findAccessorys[i],home:home)
                                        }
                                        self.saveActionSetGroup.leave()
//                                        self.tableView.reloadData()
                                    }
                                }
                            }
                }
        }
    }
    
    //以Service去找
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
    
    //更新Action
    func saveActionSetUpdate(_ actionSet: HMActionSet, chara: HMCharacteristic,acc:HMAccessory,home:HMHome) {
        //這邊自己組裝
        let a = HMCharacteristicWriteAction(characteristic: chara, targetValue: 1 as NSCopying)

            saveActionSetGroup.enter()
            addAction(a, toActionSet: actionSet) { error in
                if let error = error {
                    let createName = acc.name
                        let ouputText = "Sense: \(createName) create ok. "
                        print (ouputText)
                        
                        self.arrData.append(["name":createName,"chars":chara,"actionSet":actionSet,"acc":acc
                                             ,"home":home,"update":1])
                    
                    self.searchedDataSource = self.arrData
                        print ("*arrData: \(self.arrData)")
                        
                        self.tableView.reloadData()
                    
                    print("HomeKit: Update adding action: \(error.localizedDescription)")
                    self.saveError = error
                }else{
                    print("* nothing")
                }
                self.saveActionSetGroup.leave()
            }
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
                   
                    let createName = acc.name
                        let ouputText = "Sense: \(createName) create ok. "
                        print (ouputText)
                        
                        self.arrData.append(["name":createName,"chars":chara,"actionSet":actionSet,"acc":acc
                                             ,"home":home ,"update":0])
                    
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
                        let createName = name
                        let ouputText = "Sense: \(createName) create ok. "
                        print (ouputText)
                        
                        self.arrData.append(["name":createName,"chars":chara,"actionSet":actionSet])
                        print ("*arrData: \(self.arrData)")

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
           //閃動
           tableView.cellForRow(at: indexPath)?.blink()
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
    
    //加入動畫
    func tableView(_ tableView: UITableView,willDisplay cell: UITableViewCell,forRowAt indexPath: IndexPath)
    {
            let animation = AnimationFactory.makeMoveUpWithFade(rowHeight: cell.frame.height, duration: 0.3, delayFactor: 0.05)
            let animator = Animator(animation: animation)
            animator.animate(cell: cell, at: indexPath, in: tableView)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SenseTableViewCell
     
        if self.isShowSearchResult {
            self.home = filterDataList[indexPath.row]["home"] as! HMHome
        }else{
            self.home = arrData[indexPath.row]["home"] as! HMHome
        }
     
         let tapGesture : UITapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        tapGesture.view?.largeContentTitle = "val"
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 1
        
        var updateCode = -1         //default
        if self.isShowSearchResult {
            if let update = filterDataList[indexPath.row]["update"] {
                updateCode = update as! Int
            }
        }else{
            if let update = arrData[indexPath.row]["update"] {
                updateCode = update as! Int
            }
        }
        if updateCode == 0 {
            cell.imgSense.image = UIImage(named: "img_homeSense_new")       //new , had check sign
        }else if updateCode == 1{
            cell.imgSense.image = UIImage(named: "img_homeSense")           //old process
        }else{
            cell.imgSense.image = UIImage(named: "img_homeSense")      //other
        }
       
    
        
        cell.imgSense.isUserInteractionEnabled = true
        cell.imgSense.tag = indexPath.row
        cell.imgSense.addGestureRecognizer(tapGesture)
        
        if self.isShowSearchResult {
            // 若是有查詢結果則顯示查詢結果集合裡的資料
            let isIndexValid = filterDataList.indices.contains(indexPath.row)
            if isIndexValid{
                if let name=filterDataList[indexPath.row]["name"]{
                    cell.lbSenseName.text = name as? String
                    //介面上的情境Label字太長時捲動
                    cell.lbSenseName.type = .continuous
                    cell.lbSenseName.speed = .duration(8)
                    cell.lbSenseName.animationCurve = .easeInOut
                    cell.lbSenseName.fadeLength = 4.0
                    cell.lbSenseName.leadingBuffer = 4.0
                    cell.lbSenseName.trailingBuffer = 40.0
                    cell.lbSenseName.restartLabel()
                    //
                }
                if let home=filterDataList[indexPath.row]["home"] as? HMHome{
                    cell.lbHomeName.text = home.name
                }
                if let acc=filterDataList[indexPath.row]["acc"] as? HMAccessory{
                        if let room = acc.room {
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
                    cell.lbSenseName.text = name as? String
                    //介面上的情境Label字太長時捲動
                    cell.lbSenseName.type = .continuous
                    cell.lbSenseName.speed = .duration(8)
                    cell.lbSenseName.animationCurve = .easeInOut
                    cell.lbSenseName.fadeLength = 4.0
                    cell.lbSenseName.leadingBuffer = 4.0
                    cell.lbSenseName.trailingBuffer = 40.0
                    cell.lbSenseName.restartLabel()
                    //
                }
                if let home=arrData[indexPath.row]["home"] as? HMHome{
                    cell.lbHomeName.text = home.name
                }
                
                if let acc=arrData[indexPath.row]["acc"] as? HMAccessory{
                   
                    if let room = acc.room {
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

        //PutRoom
        let fitAction = UITableViewRowAction(style: .default, title: "Fit", handler: { (action, indexPath) in
            print("PutRoom tapped")
            
            var acc:HMAccessory?
            var home:HMHome?
            
            if self.isShowSearchResult {
                acc=self.filterDataList[indexPath.row]["acc"] as? HMAccessory
                home=self.filterDataList[indexPath.row]["home"] as? HMHome

                self.actionSet = self.filterDataList[indexPath.row]["actionSet"] as? HMActionSet
            }else{
                acc=self.arrData[indexPath.row]["acc"] as? HMAccessory
                home=self.arrData[indexPath.row]["home"] as? HMHome

                self.actionSet = self.arrData[indexPath.row]["actionSet"] as? HMActionSet
            }
            
            //--用開頭的ＸＸＸ(空格）建立新的房間
            var spliteArrAccName = acc?.name.split(separator: " ")
            let createNewRoomName = String(spliteArrAccName![0])
                var retrimString = String(spliteArrAccName![0])

                if spliteArrAccName!.count>=2 {
                    
                    self.newRoomSetGroup.enter()
                    home?.addRoom(withName: createNewRoomName) { [self] newRoom, error in
                       if let error = error {
                           print("error:\(error)")
                           return
                       }
                        
                       newRoomSetGroup.leave()
                       print ("*create new room done")
                        var foundRoomPattern = false
                        
                        for selectroom in home!.rooms {
                            print ("* selectroom.name=\(selectroom.name),\(createNewRoomName)")
                            if selectroom.name.contains(createNewRoomName) {
                                                 // Accessory裝置設定到指定房間中
                                                    self.saveAccessoryGroup.enter()
                                                    home?.assignAccessory(acc!, to: selectroom) { error in
                                                                if let error = error {
                                                                      print ("error: \(error)")

                                                                }
                                                                self.saveAccessoryGroup.leave()
                                                                foundRoomPattern = true
                                                            }
                                                            
                                                            self.saveAccessoryGroup.notify(queue: DispatchQueue.main){
                                                                
                                                            }
                                    
                                                        
                               
                                var createSenseName = acc?.name.replacingOccurrences(of:String((spliteArrAccName?[0])!)+" ", with: "")
//                                self.updateName2(createSenseName!, forAccessory: acc!)
                                                
                                                        
                
                                                        // 建立相對應情境
                                                            if self.isShowSearchResult {
                                                                self.updateNameIfNecessary2( createSenseName! ,indexPath: indexPath,acc: self.filterDataList[indexPath.row]["acc"] as! HMAccessory)
                                                            }else{
                                                            self.updateNameIfNecessary2( createSenseName! ,indexPath: indexPath,acc: self.arrData[indexPath.row]["acc"] as! HMAccessory)
                                                            }
                                                      
                                                      break
                                                  }
                                
                                        }
                   
                      
                    
                    

                    }
                }
            })
                
               
      
        
        
        //Rename
        let renameAction = UITableViewRowAction(style: .default, title: "Rename", handler: { (action, indexPath) in
            print("Rename tapped")
            
            if self.isShowSearchResult {
                self.actionSet = self.filterDataList[indexPath.row]["actionSet"] as? HMActionSet
            }else{
                self.actionSet = self.arrData[indexPath.row]["actionSet"] as? HMActionSet
            }

    
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
                            
            if self.presentedViewController==nil{
                self.present(alertController, animated: true, completion: nil)
            }else{
                self.presentedViewController!.present(alertController, animated: true, completion: nil)
            }
            
            
        })
        renameAction.backgroundColor = UIColor.blue

        // action Delete
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

        return [renameAction, deleteAction ,fitAction]
    }
 
    var selectedRoom:HMRoom?
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        print("Title tag is:\(tapGestureRecognizer.view?.largeContentTitle)")

        let tappedImage = tapGestureRecognizer.view as! UIImageView
        
        guard let indexPath = tableView.indexPathForRow(at: tapGestureRecognizer.location(in: self.tableView)) else {
            print("Error: indexPath)")
            return
        }

        print("indexPath.row: \(indexPath.row)")
        
        var pickerHome:HMHome
        arrayPickerDataSource.removeAll()
        if self.isShowSearchResult{
            pickerHome = self.filterDataList[indexPath.row]["home"] as! HMHome
            print ("pickerHome = \(pickerHome)")
            for room in pickerHome.rooms{
                print (room.name)
                if pickerHome==filterDataList[indexPath.row]["home"] as! HMHome {
                    arrayPickerDataSource.append((room,room.name))    //Value,Name
                }
            }
        }else{
//            self.arrayPickerDataSource.removeAll()
            pickerHome = self.arrData[indexPath.row]["home"] as! HMHome
            print ("pickerHome = \(pickerHome)")
            for room in pickerHome.rooms{
                print (room.name)
                if pickerHome==arrData[indexPath.row]["home"] as! HMHome {
                    arrayPickerDataSource.append((room,room.name))    //Value,Name
                }
            }
           
        }
        
        self.pickerView.setDataSource(self.arrayPickerDataSource)
        self.pickerView.reloadAll()
        
        self.pickerView.showDialog("Select Room", doneButtonTitle: "Ok", cancelButtonTitle: "cancel") { (result) -> Void in
            print (   "Selected value:\n\n Text:\(result.1)\n Value:\(result.0)" )
            self.selectedRoom = result.0 as? HMRoom  //value
            var acc=HMAccessory()
            if self.isShowSearchResult{
                acc=self.filterDataList[indexPath.row]["acc"] as! HMAccessory
            }else{
                acc=self.arrData[indexPath.row]["acc"] as! HMAccessory
            }
            
            // Accessory裝置設定到指定房間中
            self.saveAccessoryGroup.enter()
            pickerHome.assignAccessory(acc, to: self.selectedRoom!) { error in
                if let error = error {
                      print ("error: \(error)")
    //                self.displayError(error)
    //                self.didEncounterError = true
                }
                self.saveAccessoryGroup.leave()
            }
            self.saveAccessoryGroup.notify(queue: DispatchQueue.main){
                if self.isShowSearchResult{
                    self.filterDataList[indexPath.row]["home"]=pickerHome
                    self.tableView.reloadData()
                }else{
                    self.arrData[indexPath.row]["home"]=pickerHome
                    print ("* arrData \(self.arrData[indexPath.row])")
                    self.tableView.reloadData()
                }
            }
            //close picker window
            self.dismiss(animated: true, completion: {
                self.pickerView.reloadAll()
                self.arrayPickerDataSource.removeAll()
            })
        }

    }
    
    /**
        Updates the accessories name. This function will enter and leave the saved dispatch group.
        If the accessory's name is already equal to the passed-in name, this method does nothing.
        
        - parameter name:      The new name for the accessory.
        - parameter accessory: The accessory to rename.
    */
    func updateName(_ name: String, forAccessory accessory: HMAccessory) {
        if accessory.name == name {
            return
        }
        saveAccessoryGroup.enter()
        accessory.updateName(name) { error in
            if let error = error {
//                self.displayError(error)
//                self.didEncounterError = true
            }
            self.saveAccessoryGroup.leave()
        }
    }
    // MARK: HMHomeDelegate Methods
    
    // All home changes reload the view.
    
    func home(_ home: HMHome, didUpdateNameFor room: HMRoom) {
        tableView.reloadData()
    }
    
    func home(_ home: HMHome, didAdd room: HMRoom) {
        tableView.reloadData()
    }
    
    func home(_ home: HMHome, didRemove room: HMRoom)  {
//        if selectedRoom == room {
//            // Reset the selected room if ours was deleted.
//            selectedRoom = homeStore.home!.roomForEntireHome()
//        }
        tableView.reloadData()
    }
    
    func home(_ home: HMHome, didAdd accessory: HMAccessory) {
        /*
            Bridged accessories don't call the original completion handler if their
            bridges are added to the home. We must respond to `HMHomeDelegate`'s
            `home(_:didAddAccessory:)` and assign bridged accessories properly.
        */
//        if selectedRoom != nil {
//            self.home(home, assignAccessory: accessory, toRoom: selectedRoom)
//        }
    }
    
    func home(_ home: HMHome, didUnblockAccessory accessory: HMAccessory) {
        tableView.reloadData()
    }
    
    // MARK: HMAccessoryDelegate Methods
    
    /// If the accessory's name changes, we update the name field.
    func accessoryDidUpdateName(_ accessory: HMAccessory) {
//        resetNameField()
    }
    
    @IBAction func doAddRoom(_ sender: UIButton) {
            let buttonPosition = sender.convert(CGPoint(), to:tableView)
            let indexPath = tableView.indexPathForRow(at:buttonPosition)
            guard let row = indexPath?.row else { return }
            //also
            if isShowSearchResult{
                self.home = filterDataList[row]["home"] as! HMHome
            }else{
                self.home = arrData[row]["home"] as! HMHome
            }
            let alertController = UIAlertController(title: "Create room in \(home!.name)", message: "room name:", preferredStyle: UIAlertController.Style.alert)
            alertController.addTextField { (textField : UITextField!) -> Void in
                textField.placeholder = "請入要建立的房間名"
                }
        let saveAction = UIAlertAction(title: "Save", style: UIAlertAction.Style.default, handler: { [self] alert -> Void in
                if let textField = alertController.textFields?[0] {
                            if textField.text!.count > 0 {
                                print("Text :: \(textField.text ?? "")")
                                if textField.text != nil {
                                    var roomNames=[String]()
                                    for room in self.home!.rooms
                                    {
                                        roomNames.append(room.name)
                                    }
                                    if roomNames.contains(textField.text!)
                                    {
                                        let alert = UIAlertController(title: "命名重覆", message: "\(textField.text!) \n命名已存在!", preferredStyle: .alert)
                                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                                            switch action.style{
                                                case .default:
                                                    print("default")
                                                case .cancel:
                                                    print("cancel")
                                                case .destructive:
                                                print("destructive")
                                            @unknown default:
                                                break
                                            }
                                        }))
                                        self.present(alert, animated: true, completion: nil)
                                    }else{
                                        self.addRoomWithName(textField.text!)
                                    }
                                }
                            }
                        }
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.default, handler: {
                    (action : UIAlertAction!) -> Void in })
            
                alertController.addAction(saveAction)
                alertController.addAction(cancelAction)
        
            if self.presentedViewController==nil{
                self.present(alertController, animated: true, completion: nil)
            }else{
                self.presentedViewController!.present(alertController, animated: true, completion: nil)
            }
        }
    
    /**
            Adds a room to the current home.
            
            - parameter name: The name of the new room.
        */
         func addRoomWithName(_ name: String) {
             newRoomSetGroup.enter()
             home?.addRoom(withName: name) { [self] newRoom, error in
                if let error = error {
                    print("error:\(error)")
                    return
                }
                newRoomSetGroup.leave()
                print ("*done")
            }
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
                    //update Accessory name
                    self.updateName2(name, forAccessory: acc)
                    

                }else{
                    self.arrData[indexPath.row]["name"]=name
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                    //update Accessory name
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
    
    func removeTargetValueForCharacteristicOnly(_ home: HMHome?,actionSet:HMActionSet?, completion: @escaping () -> Void) {
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
     
        print ("home1\(home)")
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
    
    
    var selectedHome:HMHome?
@objc func tapChangeHome() {
         
           for home in homeManager.homes {
               arrHomePickerDataSource.append((home,home.name))
           }
           arrHomePickerDataSource.append((Optional<HMHome>.none,"(All)"))  // nil , "家"
    
           self.pickerView.setDataSource(self.arrHomePickerDataSource)
           self.pickerView.reloadAll()

           self.pickerView.showDialog("指定Home", doneButtonTitle: "Ok", cancelButtonTitle: "Cancel") { (result) -> Void in
               print (   "Selected value:\n\n Text:\(result.1)\n Value:\(result.0)" )

               if ((result.0 as? HMHome) != nil ) {
                   self.selectedHome = result.0 as? HMHome
                   self.lbTitle.text = self.selectedHome?.name
               }else{
                   if result.1 == "(All)"                            // nil , but had select(All)
                   {
                       self.selectedHome = nil
                       self.lbTitle.text = "(All)"
                   }else{                                           //cencels
                       self.lbTitle.text = self.selectedHome?.name  //restore old
                   }
               }
               self.reloadEventTableView()                          //normal refresh
               
           }
       
               //close picker window
               self.dismiss(animated: true, completion: {
                   self.arrHomePickerDataSource.removeAll()
               })
           
       }
    
     /// Starts the add accessory flow.
        @IBAction func tapAdd() {
            
            if selectedHome == nil {
            for home3 in homeManager.homes {
                arrHomePickerDataSource.append((home3,home3.name))
            }
           
            self.pickerView.setDataSource(self.arrHomePickerDataSource)
            self.pickerView.reloadAll()
            self.pickerView.showDialog("Select Home", doneButtonTitle: "Ok", cancelButtonTitle: "cancel") { (result) -> Void in
                print (   "Selected value:\n\n Text:\(result.1)\n Value:\(result.0)" )
                let selectedHome = result.0 as? HMHome  //value
                selectedHome?.addAndSetupAccessories(completionHandler: { error in
                    if let error = error {
                        print(error)
                    } else {
                        // Make no assumption about changes; just reload everything.
    //                    self.reloadData()
                    }
                })
            }
        
                //close picker window
                self.dismiss(animated: true, completion: {
                    self.arrHomePickerDataSource.removeAll()
                })
            }else{
                self.selectedHome?.addAndSetupAccessories(completionHandler: { error in
                    if let error = error {
                        print(error)
                    } else {

                    }
                })
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
           
                    //tableView.reloadData()
        } else {
    
//            isShowSearchResult = false
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
  

//更新完抓到所有的home ,first 
extension ViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
      totalCount = 0
      badgeNumber = 0
      for home1 in manager.homes {
        self.home = home1
        print ("(2)")
        print ("* read home:\(home1)")
        genSense2(for: home1)
        print ("* findcharacteristics=\(findcharacteristics)")
      }
      
  }
}

//--
//extension ViewController: HMAccessoryDelegate {
//  func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
//  }
//}

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
