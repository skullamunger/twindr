//
//  AppDelegate.swift
//  JChat
//
//  Created by DuyetTran on 1/12/19.
//  Copyright © 2019 zero2launch. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import UserNotifications
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let gcmMessageIDKey = "gcm.message_id"
    static var isToken: String? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        InstanceID.instanceID().instanceID { (result, error) in
            if let error = error {
                print("Error fetching remote instange ID: \(error)")
            } else if let result = result {
                print("Remote instance ID token: \(result.token)")
                AppDelegate.isToken = result.token
            }
        }
        UITabBar.appearance().tintColor = UIColor(red: 93/255, green: 79/255, blue: 141/255, alpha: 1)
        
        UINavigationBar.appearance().tintColor = UIColor(red: 93/255, green: 79/255, blue: 141/255, alpha: 1)
        let backImg = UIImage(named: "back")
        UINavigationBar.appearance().backIndicatorImage = backImg
        UINavigationBar.appearance().backIndicatorTransitionMaskImage = backImg
        
        UIBarButtonItem.appearance().setBackButtonTitlePositionAdjustment(UIOffset.init(horizontal: -1000, vertical: 0), for: UIBarMetrics.default)
        
        FirebaseApp.configure()
        configureInitialViewController()
        if #available(iOS 10.0, *) {
            let current = UNUserNotificationCenter.current()
            let options: UNAuthorizationOptions = [.sound, .badge, .alert]
            
            current.requestAuthorization(options: options) { (granted, error) in
                if error != nil {
                    
                } else {
                    Messaging.messaging().delegate = self
                    current.delegate = self
                    
                    DispatchQueue.main.async {
                        application.registerForRemoteNotifications()
                    }
                }
            }
        } else {
            let types: UIUserNotificationType = [.sound, .badge, .alert]
            let settings = UIUserNotificationSettings(types: types, categories: nil)
            
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        }
        
        FBSDKApplicationDelegate.sharedInstance()?.application(application, didFinishLaunchingWithOptions: launchOptions)
        GIDSignIn.sharedInstance()?.clientID = FirebaseApp.app()?.options.clientID
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handled = false
        
        if url.absoluteString.contains("fb") {
            handled = FBSDKApplicationDelegate.sharedInstance()!.application(app, open: url, options: options)
        } else {
            handled = GIDSignIn.sharedInstance()!.handle(url, sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String, annotation: [:])
        }
        
        
        return handled
    }
    
    func configureInitialViewController() {
        var initialVC: UIViewController
        let storyboard = UIStoryboard(name: "Welcome", bundle: nil)
        if Auth.auth().currentUser != nil {
            initialVC = storyboard.instantiateViewController(withIdentifier: IDENTIFIER_TABBAR)
        } else {
            initialVC = storyboard.instantiateViewController(withIdentifier: IDENTIFIER_WELCOME)
        }
        
        window?.rootViewController = initialVC
        window?.makeKeyAndVisible()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        Api.User.isOnline(bool: false)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        Api.User.isOnline(bool: false)
        Messaging.messaging().shouldEstablishDirectChannel = false

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        Api.User.isOnline(bool: true)
        connectToFirebase()

    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let messageId = userInfo[gcmMessageIDKey] {
            print("messageId: \(messageId)")
        }
        
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("messageID: \(messageID)")
        }
        connectToFirebase()
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        if let dictString = userInfo["gcm.notification.customData"] as? String {
            print("dictString \(dictString)")
            if let dict = convertToDictionary(text: dictString) {
                if let uid = dict["userId"] as? String,
                    let username = dict["username"] as? String,
                    let email = dict["email"] as? String,
                    let profileImageUrl = dict["profileImageUrl"] as? String {
                    
                    let user = User(uid: uid, username: username, email: email, profileImageUrl: profileImageUrl, status: "")
                    
                    let storyboard = UIStoryboard(name: "Welcome", bundle: nil)
                    let chatVC = storyboard.instantiateViewController(withIdentifier: IDENTIFIER_CHAT) as! ChatViewController
                    chatVC.partnerUsername = user.username
                    chatVC.partnerId = user.uid
                    chatVC.partnerUser = user
                    guard let currentVC = UIApplication.topViewController() else {
                        return
                    }
                    
                    currentVC.navigationController?.pushViewController(chatVC, animated: true)
                    
                    
                }
            }
        }
        
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func convertToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        
        return nil
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        guard let token = AppDelegate.isToken else {
            return
        }
        print("token: \(token)")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func connectToFirebase() {
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
    
    
}


extension AppDelegate: UNUserNotificationCenterDelegate, MessagingDelegate {
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        if let message = userInfo[gcmMessageIDKey] {
            print("Message: \(message)")
        }
        print(userInfo)
        
        completionHandler([.sound, .badge, .alert])
    }
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        guard let token = AppDelegate.isToken else {
            return
        }
        print("Token: \(token)")
        connectToFirebase()
    }
    
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("remoteMessage: \(remoteMessage.appData)")
    }
}
