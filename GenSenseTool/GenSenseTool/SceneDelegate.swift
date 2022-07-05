//
//  SceneDelegate.swift
//  GenSenseTool
//
//  Created by alex on 2022/5/8.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private(set) static var shared: SceneDelegate?

    var window: UIWindow?

    enum ShortcutIdentifier: String {
        case Share
        case Add
        case Scan
        
        init?(fullType: String) {
            guard let last = fullType.components(separatedBy: ".").last else { return nil }
            
            self.init(rawValue: last)
        }
        
        var type: String {
            return Bundle.main.bundleIdentifier! + ".\(self.rawValue)"
        }
    }
    
    /// Saved shortcut item used as a result of an app launch, used later when app is activated.
    var launchedShortcutItem: UIApplicationShortcutItem?
    
    func handleShortCutItem(shortcutItem: UIApplicationShortcutItem) -> Bool {
        var handled = false
        
        // Verify that the provided `shortcutItem`'s `type` is one handled by the application.
//        guard ShortcutIdentifier(fullType: shortcutItem.type) != nil else { return false }
        
        guard let shortCutType = shortcutItem.type as String? else { return false }
        
        switch (shortCutType) {
        case ShortcutIdentifier.Share.type:
            // Handle shortcut 1 (static).
            handled = true
            break
        case "tw.com.GenSenseTool.SCAN":
            // Handle shortcut 2 (static).
            handled = true
            saveItem = shortcutItem.localizedTitle
            appDelegate.mySaveType = shortcutItem.localizedTitle
            print("* appDelegate:\(appDelegate.mySaveType )")
            NotificationCenter.default.post(name: NSNotification.Name.init(rawValue: "SCAN"), object: nil, userInfo: nil)
            
            break
        default:
            break
        }
        
        // Construct an alert using the details of the shortcut used to open the application.
//        let alertController = UIAlertController(title: "Shortcut Handled", message: "\"\(shortcutItem.localizedTitle)\"", preferredStyle: .alert)
//        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
//        alertController.addAction(okAction)

//        // Display an alert indicating the shortcut selected from the home screen.
//        window!.rootViewController?.present(alertController, animated: true, completion: nil)
        
      
        return handled
    }
    
    var saveItem = ""
    var savedShortCutItem:UIApplicationShortcutItem?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
//        guard let _ = (scene as? UIWindowScene) else { return }
        
        
        if let shortcutItem = connectionOptions.shortcutItem {
                // Save it off for later when we become active.
            _ = handleShortCutItem(shortcutItem: shortcutItem)
                saveItem = shortcutItem.type
                print ("*shortcutItem =\(saveItem)")
                appDelegate.mySaveType = saveItem
            }
       
//        Self.shared = self
    }
    
    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        
        let handled = handleShortCutItem(shortcutItem: shortcutItem)
        saveItem = shortcutItem.type
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
