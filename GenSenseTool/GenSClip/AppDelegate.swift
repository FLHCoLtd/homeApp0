//
//  AppDelegate.swift
//  GenSClip
//
//  Created by alex on 2022/6/1.
//

import UIKit
import AppClip
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

     var theURLString = ""
     var locationString = "xxx"
    
     func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                              restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
         verifyUserLocation(userActivity)
       return true
    }
    
    // Call the verifyUserLocation(_:) function in all applicable lifecycle callbacks.

       func verifyUserLocation(_ activity: NSUserActivity?) {
           
           // Guard against faulty data.
           guard activity != nil else { return }
           guard activity!.activityType == NSUserActivityTypeBrowsingWeb else { return }
           guard let payload = activity!.appClipActivationPayload else { return }
           guard let incomingURL = activity?.webpageURL else { return }

           // Create a CLRegion object.
           guard let region = location(from: incomingURL) else {
               // Respond to parsing errors here.
               return
           }
           
           // Verify that the invocation happened at the expected location.
           // 驗證調用是否發生在預期的位置。
           payload.confirmAcquired(in: region) { (inRegion, error) in
               guard let confirmationError = error as? APActivationPayloadError else {
                   if inRegion {
                       // The location of the NFC tag matches the user's location.
                       print ( "* NFC 標籤的位置與用戶的位置相匹配" )
                       DispatchQueue.main.async {
                           let appDelegate = UIApplication.shared.delegate as! AppDelegate
                           appDelegate.locationString = "在地區使用"
                       }
                   } else {
                       // The location of the NFC tag doesn't match the records;
                       // for example, if someone moved the NFC tag.
                       print ("* NFC標籤的位置與記錄不符")
                       DispatchQueue.main.async {
                           let appDelegate = UIApplication.shared.delegate as! AppDelegate
                           appDelegate.locationString = "非在地區使用"
                       }
                   }
                   return
               }
               
               if confirmationError.code == .doesNotMatch {
                   // The scanned URL wasn't registered for the App Clip.
                   print ("* 掃描的 URL 沒有註冊到App Clip")
               } else {
                   // The user denied location access, or the source of the
                   // App Clip’s invocation wasn’t an NFC tag or visual code.
                   print ("* 用戶拒絕位置訪問，或 App Clip 的調用不是 NFC 標籤或可視代碼。")
               }
           }
       }

       func location(from url:URL) -> CLRegion? {
           let coordinates = CLLocationCoordinate2D(latitude: 24.97761,
                                                    longitude:121.322450)
           return CLCircularRegion(center: coordinates,
                                   radius: 500,
                                   identifier: "Home")
       }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

