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

  // 1. For discovering new accessories

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

	// 7. Handle touches which toggle the state of the lightbulb
  }

  private func loadAccessories() {
    guard let homeAccessories = home?.accessories else {
      return
    }

    collectionView?.reloadData()
  }

  @objc func discoverAccessories(sender: UIBarButtonItem) {
    activityIndicator.startAnimating()
    navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)

	// 2. Start discovery
  }

  @objc private func stopDiscoveringAccessories() {
    navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(discoverAccessories(sender:)))
	// 4. Stop discovering
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

// 3. Have AccessoryViewController implement HMAccessoryBrowserDelegate

// 6. Have AccessoryViewController implement HMAccessoryDelegate to detect changes in accessory

extension HMAccessory {
  func find(serviceType: String, characteristicType: String) -> HMCharacteristic? {
    return services.lazy
      .filter { $0.serviceType == serviceType }
      .flatMap { $0.characteristics }
      .first { $0.metadata?.format == characteristicType }
  }
}

