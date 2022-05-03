HomeKit is a library that allows users to use their Apple devices configure, communicate and control smart-home devices.

The HomeKit framework allows your apps to easily setup and control your HomeKit accessories. It provides a central store for the configuration these accessories in your home. Configuration is synchronized across all your apps and devices and is deeply integrated into iOS, WatchOS and tvOS.

HomeKit even provides you with a way to control accessories, or automation using Siri voice commands.

Before you learn how to control accessories from your app, its best to understand how Apple identifies pieces inside HomeKit.

At the root, HomeKit defines Homes, with one being designated as the "primary home". Every home needs to have a unique name, so when you ask Siri to interact with your home, it can easily identify if you mean your summer home, or your winter home. Unique names is a fixed requirement across each piece of HomeKit. Each home can have one or many rooms, and any one room can have one or many accessories. The idea of a unique name applies to both rooms and accessories.

Each accessory can be equipped with one or more services. Think of services as the capabilities of an accessory, like a ceiling fan with lights. In the case of the ceiling fan, it has two services, one for the fan, and one for the light. Finally, each service can have one or more of its own characteristics. A characteristic is a specific trait or value type associated with that service. So using our ceiling fan analogy, the fan service might have a speed characteristic. The light in the ceiling fan might have two characteristics, one for intensity and another for color.

The point is, devices can expose their characteristics, and developers can have granular control over how users interact with an accessory.

In this tutorial, we'll go over each of these pieces in an app that'll control the on/off state of a lightbulb.

Now, you may or may not have a HomeKit device available to you, however, in this tutorial, we'll make use of a simulator provided by Apple to create simulator HomeKit devices.

The easiest way to get the simulator is to open up the starter app, select the "LightSwitch" project in the Project Navigator, and selecting the "Capabilities" tab. In the list that appears, you should see an option for "HomeKit" with a toggle button set to "off". Enable it, and you should see a button with the text "Download HomeKit Simulator". Pressing the button will open a browser to your Apple Developer download page. Here, you'll have to search for "Hardware IO Tools for Xcode 7.3". Once you've found it, download it, and install. You will have to select the "HomeKit Accessory Simulator" app and move it into your Applications folder.

Once you've installed it, launch the simulator. In the left pane, you should see an empty list of Accessories. Clicking the "+" at the bottom of the list will prompt you with a dialog to create a new accessory. Give the accessory a name, and leave other fields blank. The first thing you'll note is that each device is given a unique "Setup Code". This code is used to pair and register a device when its on your network.

At the moment, your accessory has no service. Which is a sad existence for an accessory. Click the "Add Service..." button at the bottom of the page. In the dialog, you can see a dropdown selector next to Service. You can see that there are a number of "predefined" category of services that HomeKit lets you choose from, including a "Custom" category. Take a minute to go through them all, and when ready, select "Lightbulb". Feel free to give this service a name. You can see that the Lightbulb service, already comes with some predefined characteristics. You should see "On", "Brightness", "Hue" and "Saturation" as characteristics of the service. For the purposes of this demo, we can remove the last three characteristics and just focus on the "On" state of the characteristic. Congratulations, you've created your first HomeKit device!

Head back to the starter project. Recall when you enabled the HomeKit capabilities, this also added the necessary entitlements needed by the app to use HomeKit. Next you'll need to add some entries in the project's info.plist file. Because we're working with a user's private data, therefore we need permission to read/write that data. In the Info.plist, add a key named "Privacy - HomeKit Usage Description".

In order to start interacting with HomeKit, open up `HomeController.swift`, here, add a reference to the `HMHomeManager`. This object will give you access to all things HomeKit.

```
// 1. Add the homeManager
let homeManager = HMHomeManager()
```

Once its been added, you can access all the homes known to HomeKit by accessing the `homes` property on the `homeManager`. Do this in the `viewDidLoad()` method.

```
// 2. Add homes from homeManager
addHomes(homeManager.homes)
```

Since changes to homes, can happen on any device synchronized with your account, you can add a delegate to the `homeManager` to get notifications of changes to any homes. First assign yourself as a delegate in the `init?` of `HomeController`.

```
// 3. Add HomeController as delegate to Home
homeManager.delegate = self
```

Next you'll need to implement the optional delegate methods. Do this by extending the `HomeController` with the `HMHomeManagerDelegate` protocol, and implement `homeManagerDidUpdateHomes()` method.

```
// 4. Implement HMHomeManagerDelegate as extension on HomeController
extension HomeViewController: HMHomeManagerDelegate {
  func homeManagerDidUpdateHomes(_ manager: HMHomeManager) {
    addHomes(manager.homes)
  }
}
```

Not everyone will already have a `Home` defined in HomeKit, so while we're here, let's add the ability to to create our own home and give it a Room.

```
// 5. Add new Home + Room
self.homeManager.addHome(withName: homeName, completionHandler: { (home, error) in
	if let error = error {
		print("Failed to add home: \(error.localizedDescription)")
	}
	if let discoveredHome = home {
		discoveredHome.addRoom(withName: roomName, completionHandler: { _, error  in
			if let error = error {
				print("Failed to add room: \(error.localizedDescription)")
			} else {
				self.homes.append(discoveredHome)
				self.collectionView?.reloadData()
			}
		})
	}
})
```
You should now see a list of homes associated to your Home. Next let's try to add your lightbulb device to the home and room you just created. Open `AccessoryViewController`.

Accessories cannot be added the same way Homes were added previously. Accessories need to be discovered before they can be added to a given Home and Room. To do this, add an instance of `HMAccessoryBrowser` as a property to the class, along with a list of `HMAccessory`, which you'll use to keep track of all of the discovered accessories.

```
// 1. For discovering new accessories
let browser = HMAccessoryBrowser()
var discoveredAccessories = [HMAccessory]()
```

In menu item callback  `discoverAccessories()`, you'll reset the list of discovered accessories, assign `AccessoryViewController` as a delegate to the `HMAccessoryBrowser`. You'll also have the browser start the discovery, and start a timer to stop searching after 10 seconds.

```
// 2. Start discovery
discoveredAccessories.removeAll()
browser.delegate = self
browser.startSearchingForNewAccessories()
perform(#selector(stopDiscoveringAccessories), with: nil, afterDelay: 10)
```

As a delegate of `HMAccessoryBrowser`, you have to implement the `HMAccessoryBrowserDelegate` protocol. This callback will be invoked when HomeKit discovers a new accessory during the search phase. In this app, we'll just record when a new accessory has been found, and we'll analyze the results after the timer completes.

```
// 3. Have AccessoryViewController implement HMAccessoryBrowserDelegate
extension AccessoryViewController: HMAccessoryBrowserDelegate {
  func accessoryBrowser(_ browser: HMAccessoryBrowser, didFindNewAccessory accessory: HMAccessory) {
    discoveredAccessories.append(accessory)
  }
}
```

After 10 seconds, the timer will call `stopDiscoveringAccessories`. The following method will see if any accessories were discovered. In this app, you'll just add all discovered accessories to the selected home. Note that we'll just add the accessory to the home. Normally you'd want to add it to a certain `HMRoom` for better management, but in the interest of time, we'll just add it to the home.

```
// 4. Stop discovering
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
```

Ok, so now that the accessories have been added to the Home, there's still work to be done to be able to control the on/off state of the lightbulb. However, we'll first have to display all known accessories. In `loadAccessories()`, add the following code. It will first sort through all of a home's accessories, and try to find an accessory with a service that matches the `HMServiceTypeLightbulb` type, and has a Boolean (on/off) characteristic format.

Once the characteristic has been found to exist in the accessory, you'll enable notification on that characteristic and add `AccessoryViewController` as a delegate to the accessory.

```
// 5. Load accessories
for accessory in homeAccessories {
	if let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatBool) {
		accessories.append(accessory)
		accessory.delegate = self
		characteristic.enableNotification(true, completionHandler: { (error) -> Void in
			if error != nil {
				print("Something went wrong when enabling notification for a characteristic.")
			}
		})
	}
}
```

Adding the `AccessoryViewController` as the delegate to the accessory and enabling notifications on its characteristic means that you'll receive a callback when the value of the characteristic changes. Here, you'll simply have the table reload itself, when that value changes. All that's left is to handle the actual changing of the on/off value.

```
// 6. Have AccessoryViewController implement HMAccessoryDelegate to detect changes in accessory
extension AccessoryViewController: HMAccessoryDelegate {
  func accessory(_ accessory: HMAccessory, service: HMService, didUpdateValueFor characteristic: HMCharacteristic) {
    collectionView?.reloadData()
  }
}
```

Finally, in `collectionView(_, didSelectItemAt:)`, you'll toggle the value of the on/off state in the lightbulb. The easiest way to do this is to use the asynchronous method `writeValue` on the characteristic whose value needs to be changed.

```
// 7. Handle touches which toggle the state of the lightbulb
guard let characteristic = accessory.find(serviceType: HMServiceTypeLightbulb, characteristicType: HMCharacteristicMetadataFormatBool) else {
	return
}

let toggleState = (characteristic.value as! Bool) ? false : true
characteristic.writeValue(NSNumber(value: toggleState), completionHandler: { (error) -> Void in
	if error != nil {
		print("Something went wrong when attempting to update the service characteristic.")
	}
	collectionView.reloadData()
})
```

And that's it! HomeKit is a great library to help you interact with all your HomeKit enabled devices. Although we didn't have time to go over it in this screencast, HomeKit gives you the ability to set up scenes and automations, which are groups of actions that affect the accessories in your smart home. HomeKit also allows you to create action triggers based on calendar values, or geo location.
