//
//  SceneDelegate.swift
//  GenSClip
//
//  Created by alex on 2022/6/1.
//

import UIKit
import AppClip
import CoreLocation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb else { return }
        guard let url = userActivity.webpageURL else { return }
        
        verifyUserLocation(userActivity)
        
        presentExperience(for: url)
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
                   } else {
                       // The location of the NFC tag doesn't match the records;
                       // for example, if someone moved the NFC tag.
                       print ("* NFC標籤的位置與記錄不符")
                   }
                   return
               }
               
               if confirmationError.code == .doesNotMatch {
                   // The scanned URL wasn't registered for the App Clip.
                   print ("* 掃描的 URL 沒有註冊到App Clip")
               } else {
                   // The user denied location access, or the source of the
                   // App Clip’s invocation wasn’t an NFC tag or visual code.
                   print ("* 用戶拒絕位置訪問，或 App Clip 的調用不是 NFC 標籤 或Clip可視條碼。")
               }
           }
       }

       func location(from url:URL) -> CLRegion? {
           
           //Taipei 101
           let coordinates = CLLocationCoordinate2D(latitude: 25.03384733,
                                                    longitude:121.5644525)
           return CLCircularRegion(center: coordinates,
                                   radius: 500,
                                   identifier: "Taipei 101")
       }
    
    func presentExperience(for url: URL) {
        // Route user to the appropriate place in your App Clip.
        print ("Clip presentExperience:" + url.absoluteString)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.theURLString = url.absoluteString
    }
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}

