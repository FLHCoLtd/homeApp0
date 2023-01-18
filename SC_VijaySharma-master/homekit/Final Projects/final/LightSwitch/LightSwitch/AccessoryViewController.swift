/// Copyright (c) 2018 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE

import UIKit
import HomeKit
import Matter
import MatterSupport

class AccessoryViewController: BaseCollectionViewController {
  let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
  var accessories = [HMAccessory]()
  var home: HMHome? = nil

  // For discovering new accessories
  let browser = HMAccessoryBrowser()
  var discoveredAccessories = [HMAccessory]()

  var passCharacteristicH:HMCharacteristic?
  var passCharacteristicS:HMCharacteristic?
  var passCharacteristicB:HMCharacteristic?
  var passCharacteristic:HMCharacteristic?
  var passOnoff = false
  var passBright = 0
  var passHue = 0
  var passSat = 0
  var passTemper = 0
  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.addObserver(self, selector: #selector(reloadCollectionView), name: Notification.Name("ReloadCollectionView"), object: nil)
      
  let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
      collectionView?.addGestureRecognizer(longPressGesture)
      
    title = "\(home?.name ?? "") Accessories"
//    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(discoverAccessories(sender:)))


      let scan = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(scanBarcode(sender:)))
      let search = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(discoverAccessories(sender:)))
      navigationItem.rightBarButtonItems = [search , scan]  //由右->往左
      
      
    loadAccessories()
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return accessories.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let accessory = accessories[indexPath.row]

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! AccessoryCell
      print("* accessory:\(accessory)")
	cell.accessory = accessory
	
    return cell
  }

    
  @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                guard let selectedIndexPath = collectionView?.indexPathForItem(at: gesture.location(in: collectionView)) else {
                    break
                }
                //===
                let accessory = accessories[selectedIndexPath.row]

                  print("accessory.matterNodeID: \(accessory.matterNodeID)")
//                accessory.MatterAddDeviceRequest
           
                    
                
                      
 
                  guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatInt) else {
                    return
                  }
                    if let _ = characteristic.value {     //安全解包
                        let brightInt = (characteristic.value as! Int)
                        print("brightInt=\(brightInt)")
                        passBright = brightInt
                        self.passCharacteristicB = characteristic
//                        characteristic.writeValue(NSNumber(value: passBright), completionHandler: { (error) -> Void in
//                            if error != nil {
//                                print("Something went wrong when attempting to update the service characteristic.")
//                            }
//                            self.collectionView?.reloadData()
//                        })
                    }
                //===
                guard let characteristic = accessory.findX(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeHue) else {
                    return
                  }
                    if let _ = characteristic.value {     //安全解包
                        let HueInt = (characteristic.value as! Int)
                        print("HueInt=\(HueInt)")
                        passHue = HueInt
                        self.passCharacteristicH = characteristic
//                        characteristic.writeValue(NSNumber(value: passHue), completionHandler: { (error) -> Void in
//                            if error != nil {
//                                print("Something went wrong when attempting to update the service characteristic.")
//                            }
//                            self.collectionView?.reloadData()
//                        })
                    }
                //===
                guard let characteristic = accessory.findX(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeSaturation) else {
                    return
                  }
                    if let _ = characteristic.value {     //安全解包
                        let SatInt = (characteristic.value as! Int)
                        print("SatInt=\(SatInt)")
                        passSat = SatInt
                        self.passCharacteristicS = characteristic
//                        characteristic.writeValue(NSNumber(value: passHue), completionHandler: { (error) -> Void in
//                            if error != nil {
//                                print("Something went wrong when attempting to update the service characteristic.")
//                            }
//                            self.collectionView?.reloadData()
//                        })
                    }
                //===
                guard let characteristic = accessory.findX(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicTypeColorTemperature) else {
                    return
                  }
                    if let _ = characteristic.value {     //安全解包
                        let valueInt = (characteristic.value as! Int)
                        print("passTemper=\(valueInt)")
                        passTemper = valueInt
                        self.passCharacteristic = characteristic
//                        characteristic.writeValue(NSNumber(value: passHue), completionHandler: { (error) -> Void in
//                            if error != nil {
//                                print("Something went wrong when attempting to update the service characteristic.")
//                            }
//                            self.collectionView?.reloadData()
//                        })
                    }
                collectionView?.beginInteractiveMovementForItem(at: selectedIndexPath)
            case .changed:
                collectionView?.updateInteractiveMovementTargetPosition(gesture.location(in: gesture.view!))
            case .ended:
                collectionView?.endInteractiveMovement()
               
           performSegue(withIdentifier: "toDetail", sender: nil)
                
            default:
                collectionView?.cancelInteractiveMovement()
            }
        }
    
    
  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)

    let accessory = accessories[indexPath.row]
 
     
      //HMServiceTypeLightbulb 燈泡
      //HMServiceTypeSwitch    開關
    print ("*accessory1: \(accessory)")
    print("accessory.matterNodeID: \(accessory.matterNodeID)")
//    print("accessory.matterPayload: \(accessory.matterPayload)")
//    print("accessory.matterControllerID: \(accessory.matterControllerID)")
    //accessory.MatterAddDeviceRequest
 
          
      guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatBool) else {
      return
    }
      passCharacteristic = characteristic
      if let _ = characteristic.value {     //安全解包
        
          let toggleState = (characteristic.value as! Bool) ? false : true
          passOnoff = toggleState
          characteristic.writeValue(NSNumber(value: toggleState), completionHandler: { (error) -> Void in
              if error != nil {
                  print("Something went wrong when attempting to update the service characteristic.")
              }
              collectionView.reloadData()
          })
      }
      
//    //===
//      guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatInt) else {
//        return
//      }
//        if let _ = characteristic.value {     //安全解包
//            let brightInt = (characteristic.value as! Int)
//            print("brightInt=\(brightInt)")
//            passBright = brightInt
//
////            performSegue(withIdentifier: "toDetail", sender: nil)
//            self.passCharacteristic = characteristic
//            characteristic.writeValue(NSNumber(value: passBright), completionHandler: { (error) -> Void in
//                if error != nil {
//                    print("Something went wrong when attempting to update the service characteristic.")
//                }
//                collectionView.reloadData()
//            })
//        }
      
  }

  private func loadAccessories() {
    guard let homeAccessories = home?.accessories else {
      return
    }

      for accessory in homeAccessories {
          if let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatInt) {
              
              //找出Matter裝置
//              if  accessory.name.contains("Matter"){
                  accessories.append(accessory)
                  accessory.delegate = self
                  characteristic.enableNotification(true, completionHandler: { (error) -> Void in
                      if error != nil {
                          print("Something went wrong when enabling notification for a chracteristic.")
                      }
                  })
//              }
          }
          
      }

    collectionView?.reloadData()
  }

    @objc func reloadCollectionView()
    {
        collectionView?.reloadData()
    }
    
    @objc func scanBarcode(sender: UIBarButtonItem) async {
        
        let request = MatterAddDeviceRequest(
            topology: .init(ecosystemName: "Acme SmartHome", homes: [
                .init(displayName: "Default Acme Home"),
            ])
        )
    
        // Perform the request
        do {
            try await request.perform()
            print("Successfully set up a device!")
        } catch {
            print("Failed to set up a device with error: \(error)")
        }
        
//        home?.addAndSetupAccessories(completionHandler: { error in
//              if let error = error {
//                  print(error)
//              } else {
//                  // Make no assumption about changes; just reload everything.
//
//              }
//          })
      }
    
  @objc func discoverAccessories(sender: UIBarButtonItem) {
    activityIndicator.startAnimating()
//    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
      navigationItem.rightBarButtonItems?[0] = UIBarButtonItem(customView: activityIndicator)
    discoveredAccessories.removeAll()
    browser.delegate = self
    browser.startSearchingForNewAccessories()
    perform(#selector(stopDiscoveringAccessories), with: nil, afterDelay: 10)
  }

  @objc private func stopDiscoveringAccessories() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(discoverAccessories(sender:)))
    if discoveredAccessories.isEmpty {
      let alert = UIAlertController(title: "No Accessories Found", message: "No Accessories were found. Make sure your accessory is nearby and on the same network.", preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .default))
      present(alert, animated: true)
    } else {
      let homeName = home?.name
      let alert = UIAlertController(title: "Accessories Found", message: "A total of \(discoveredAccessories.count) were found. They will all be added to your home '\(homeName ?? "")'.", preferredStyle: UIAlertControllerStyle.alert)
      alert.addAction(UIAlertAction(title: "Cancel", style: .default))
      alert.addAction(UIAlertAction(title: "OK", style: .default) { action in
        self.addAccessories(self.discoveredAccessories)
      })
      present(alert, animated: true)
    }
  }

  private func addAccessories(_ accessories: [HMAccessory]) {
    for accessory in accessories {
      home?.addAccessory(accessory) { error in
        if let error = error {
          print("Failed to add accessory to home: \(error.localizedDescription)")
        } else {
          self.loadAccessories()
        }
      }
    }
  }
//第一個 view controller 中
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toDetail" {
            let secondVC = segue.destination as! DetailViewController
            secondVC.PrevVC = self
//            secondVC.data = "Hello, World!"
        }
    }
    
}

extension AccessoryViewController: HMAccessoryDelegate {
  func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
    collectionView?.reloadData()
  }
}

extension AccessoryViewController: HMAccessoryBrowserDelegate {
  func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
    discoveredAccessories.append(accessory)
  }
}



extension HMAccessory {
    
  //資料內容 Find
  func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
    return services.lazy
      .filter { $0.serviceType == serviceType }
      .flatMap { $0.characteristics }
      .first { $0.metadata?.format == characteristicType }
  }
    
  //資料Type Find
    func findX(serviceType: String, characteristicType: String) -> HMCharacteristic? {
      return services.lazy
        .filter { $0.serviceType == serviceType}
        .flatMap { $0.characteristics }
        .first { $0.characteristicType == characteristicType }
    }
    
}

