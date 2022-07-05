//
//  SceneDelegate.swift
//  GenSenseTool
//
//  Created by alex on 2022/5/8.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        switch (shortCutType) {
//        case ShortcutIdentifier.Share.type:
//            // Handle shortcut 1 (static).
//            handled = true
//            break
        case ShortcutIdentifier.Scan.type:
            // Handle shortcut 2 (static).
            handled = true
            saveItem = shortcutItem.localizedTitle
            appDelegate.mySaveType = shortcutItem.type
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "SCAN"), object: nil, userInfo: nil)
            break
        default:
            break
        }

        return handled
    }
    
    var saveItem = ""
    //未從執行過程式解析QuickAction
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
        guard let _ = (scene as? UIWindowScene) else { return }
        
        if let shortcutItem = connectionOptions.shortcutItem {
                // Save it off for later when we become active.
            _ = handleShortCutItem(shortcutItem: shortcutItem)
                saveItem = shortcutItem.localizedTitle
                appDelegate.mySaveType = shortcutItem.type
            }
    }
    
    //程式有執行從QuickAction來
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        
        let handled = handleShortCutItem(shortcutItem: shortcutItem)
        saveItem = shortcutItem.localizedTitle
        appDelegate.mySaveType = shortcutItem.type
        print ("*shortcutItem =\(saveItem)")
        
        completionHandler(handled)
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

extension SceneDelegate {
    var appDelegate: AppDelegate {
    return UIApplication.shared.delegate as! AppDelegate
   }
}
