//
//  AppDelegate.swift
//  Prey
//
//  Created by Javier Cala Uribe on 5/8/14.
//  Copyright (c) 2014 Fork Ltd. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, AppsFlyerTrackerDelegate {
    
    // MARK: Properties
    
    var window: UIWindow?

    // MARK: Methods
    
    // Display screen
    func displayScreen() {
        
        // Check PreyModule Status
        PreyModule.sharedInstance.checkActionArrayStatus()
        
        // Relaunch viewController
        let homeIdentifier                  = (PreyConfig.sharedInstance.isCamouflageMode) ? StoryboardIdVC.home.rawValue : StoryboardIdVC.homeWeb.rawValue
        self.window                         = UIWindow(frame: UIScreen.main.bounds)
        let mainStoryboard: UIStoryboard    = UIStoryboard(name:StoryboardIdVC.PreyStoryBoard.rawValue, bundle: nil)
        let rootVC: UINavigationController  = mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.navigation.rawValue) as! UINavigationController
        let controller: UIViewController    = (PreyConfig.sharedInstance.isRegistered) ? mainStoryboard.instantiateViewController(withIdentifier: homeIdentifier) :
            mainStoryboard.instantiateViewController(withIdentifier: StoryboardIdVC.welcome.rawValue)
        
        rootVC.setViewControllers([controller], animated: false)
        
        self.window?.rootViewController = rootVC
        self.window?.makeKeyAndVisible()
    }
    
    // MARK: UIApplicationDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // FIXME: Update devKey AppsFlyer
        // Config AppsFlyer SDK
        AppsFlyerTracker.shared().appsFlyerDevKey = "d3vk3y"
        AppsFlyerTracker.shared().appleAppID = "456755037"
        AppsFlyerTracker.shared().delegate = self
        #if DEBUG
        AppsFlyerTracker.shared().isDebug = true
        #endif
        
        // FIXME: Update apikey crashlytics        
        // Config Fabric SDK
        Fabric.with([Crashlytics.self])
        
        // Config Google Analytics
        GAI.sharedInstance().tracker(withTrackingId: GAICode)
        GAI.sharedInstance().trackUncaughtExceptions                = true
        GAI.sharedInstance().dispatchInterval                       = 120
        GAI.sharedInstance().logger.logLevel                        = GAILogLevel.none
        GAI.sharedInstance().defaultTracker.allowIDFACollection     = true

        // Update current localUserSettings with preview versions
        PreyConfig.sharedInstance.updateUserSettings()        
        
        // Config init UIViewController
        displayScreen()
        
        // Config UINavigationBar
        PreyConfig.sharedInstance.configNavigationBar()
        
        // Check notification_id with server
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.registerForRemoteNotifications()
        } else {
            PreyDeployment.sharedInstance.runPreyDeployment()
        }
        
        // Check CLRegion In/Out
        if let locationLaunch = launchOptions?[UIApplication.LaunchOptionsKey.location] {
            PreyLogger("Prey Geofence received while not running: \(locationLaunch)")
            _ = GeofencingManager.sharedInstance
        }
        
        // Check user is Pro
        if PreyConfig.sharedInstance.isPro {
            // Init geofencing region
            _ = GeofencingManager.sharedInstance
        }
        
        return true
    }    
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        // Hide mainView for multitasking preview
        let backgroundImg   = UIImageView(image:UIImage(named:"BgWelcome"))
        backgroundImg.frame = UIScreen.main.bounds
        backgroundImg.alpha = 0
        backgroundImg.tag   = 1985
        
        window?.addSubview(backgroundImg)
        window?.bringSubviewToFront(backgroundImg)
        
        UIView.animate(withDuration: 0.2, animations:{() in backgroundImg.alpha = 1.0})
        
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        PreyLogger("Prey is in background")
        // Hide keyboard
        window?.endEditing(true)
        
        if PreyConfig.sharedInstance.isRegistered {
            // Check if viewController is HomeWebVC
            if let rootVC = window?.rootViewController as? UINavigationController {
                if let controller = rootVC.topViewController {
                    if controller is HomeWebVC {
                        return
                    }
                }
            }
            for view:UIView in (window?.subviews)! {
                if view.tag != 1985 {
                    view.removeFromSuperview()
                }
            }
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
    }

    func applicationDidBecomeActive(_ application: UIApplication) {

        // Track Installs, updates & sessions(app opens)
        AppsFlyerTracker.shared().trackAppLaunch()

        // Show mainView
        let backgroundImg   = window?.viewWithTag(1985)
        
        UIView.animate(withDuration: 0.2, animations:{() in backgroundImg?.alpha = 0},
                                   completion:{(Bool)  in backgroundImg?.removeFromSuperview()})
        
        // Relaunch window
        if  window?.rootViewController?.view.superview == window {
            return
        }

        // Check if viewController is QRCodeVC
        if let controller = window?.rootViewController?.presentedViewController {
            if controller is QRCodeScannerVC {
                return
            }
        }
        
        window?.endEditing(true)
        displayScreen()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Show notification to keep background
        let userInfo : [String:String]      = ["keep_background" : "url"]
        let localNotif                      = UILocalNotification()
        localNotif.userInfo                 = userInfo
        localNotif.alertBody                = "Keep Prey in background to enable all of its features.".localized
        localNotif.hasAction                = false
        localNotif.soundName                = UILocalNotificationDefaultSoundName
        application.presentLocalNotificationNow(localNotif)
    }
    
    // MARK: Notification
    
    // Did register notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.didRegisterForRemoteNotificationsWithDeviceToken(deviceToken)
        }
    }
    
    // Fail register notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PreyLogger("Error Register Notification: \(error)")
    }
    
    // Did receive remote notification
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if PreyConfig.sharedInstance.isRegistered {
            PreyNotification.sharedInstance.didReceiveRemoteNotifications(userInfo, completionHandler:completionHandler)
        }
    }
    
    // Did receiveLocalNotification
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        PreyLogger("Local notification received")
        PreyNotification.sharedInstance.checkLocalNotification(application, localNotification:notification)
    }
    
    // MARK: AppsFlyer Delegate Deep Linking
    
    // Reports app open from a Universal Link for iOS 9 or later
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if #available(iOS 9.0, *) {
            AppsFlyerTracker.shared().continue(userActivity, restorationHandler: restorationHandler as? ([Any]?) -> Void)
        }
        return true
    }
    
    // Reports app open from deep link from apps which do not support Universal Links (Twitter) and for iOS8 and below
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        AppsFlyerTracker.shared().handleOpen(url, sourceApplication: sourceApplication, withAnnotation: annotation)
        return true
    }
    
    // Reports app open from deep link for iOS 10 or later
    @available(iOS 9.0, *)
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        AppsFlyerTracker.shared().handleOpen(url, options: options)
        return true
    }
}

