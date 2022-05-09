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

class AccessoryViewController: BaseCollectionViewController {
  let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
  var accessories = [HMAccessory]()
  var home: HMHome? = nil

  // For discovering new accessories
  let browser = HMAccessoryBrowser()
  var discoveredAccessories = [HMAccessory]()

  override func viewDidLoad() {
    super.viewDidLoad()

    title = "\(home?.name ?? "") Accessories"
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(discoverAccessories(sender:)))

    loadAccessories()
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return accessories.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let accessory = accessories[indexPath.row]

    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "itemCell", for: indexPath) as! AccessoryCell
	cell.accessory = accessory
	
    return cell
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    collectionView.deselectItem(at: indexPath, animated: true)

    let accessory = accessories[indexPath.row]

//    guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatBool) else {
//      return
//    }
      
    guard let characteristic = accessory.find(serviceType: HMServiceTypeSwitch, characteristicType: HMCharacteristicMetadataFormatBool) else {
        return
    }

    let toggleState = (characteristic.value as! Bool) ? false : true
    
    characteristic.writeValue(NSNumber(value: toggleState), completionHandler: { (error) -> Void in
      if error != nil {
        print("Something went wrong when attempting to update the service characteristic.")
      }
      collectionView.reloadData()
    })
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

    collectionView?.reloadData()
  }

  @objc func discoverAccessories(sender: UIBarButtonItem) {
    activityIndicator.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

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
  func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
    return services.lazy
      .filter { $0.serviceType == serviceType }
      .flatMap { $0.characteristics }
      .first { $0.metadata?.format == characteristicType }
  }
}

