//
//  AppDelegate.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/12.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import Accelerate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?
	var frostedViewController: REFrostedViewController?
	var usernameOfTesSoMe: String? = nil
	var passwordOfTesSoMe: String? = nil
	let ud = NSUserDefaults()


	func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
		// Override point for customization after application launch.
		let serviceName = "TesSoMe"
		let accounts = SSKeychain.accountsForService(serviceName)
		if accounts != nil {
			let account = accounts.last as? NSDictionary
			usernameOfTesSoMe = account!["acct"] as? String
			passwordOfTesSoMe = SSKeychain.passwordForService(serviceName, account: usernameOfTesSoMe)
		}
		
		initUserDefault()
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let topicMenuView = storyboard.instantiateViewControllerWithIdentifier("TopicMenuView") as UITableViewController
		let rootTabBarController = storyboard.instantiateViewControllerWithIdentifier("RootTabBarController") as UITabBarController
		
		frostedViewController = REFrostedViewController(contentViewController: rootTabBarController, menuViewController: topicMenuView)
		frostedViewController!.direction = .Left
		frostedViewController!.liveBlur = true
		frostedViewController!.menuViewController.view.backgroundColor = UIColor.clearColor()
		
		self.window?.rootViewController = frostedViewController
		
		return true
	}
	
	func application(application: UIApplication, openURL url: NSURL, sourceApplication: String, annotation: AnyObject?) -> Bool {
		switch url.host! {
		case "post":
			let storyboard = UIStoryboard(name: "PostMessage", bundle: nil)
			let postNavigationController = storyboard.instantiateViewControllerWithIdentifier("PostNavigation") as UINavigationController
			let postViewController = postNavigationController.viewControllers.first as PostMainViewController
			
			if let query = url.query {
				let postText = query.stringByReplacingOccurrencesOfString("^text=", withString: "", options: .RegularExpressionSearch).stringByRemovingPercentEncoding!
				println(postText)
				postViewController.preparedText = postText
			}
			
			self.window?.rootViewController!.presentViewController(postNavigationController, animated: true, completion: nil)

		default:
			return false
		}
		return true

	}

	func initUserDefault() {
		let defaultConfig = NSMutableDictionary.dictionary()
		defaultConfig.setObject(true, forKey: "relativeTimestamp")
		defaultConfig.setObject(11.0, forKey: "fontSize")
		defaultConfig.setObject(true, forKey: "badge")
		defaultConfig.setObject(false, forKey: "viaSignature")
		defaultConfig.setObject(true, forKey: "backgroundNotification")
		defaultConfig.setObject(true, forKey: "vibratingNotification")
		defaultConfig.setObject(true, forKey: "streaming")
		defaultConfig.setObject(10.0, forKey: "interval")
		defaultConfig.setObject(false, forKey: "debug")
		defaultConfig.setObject(false, forKey: "detailNetwork")
		ud.registerDefaults(defaultConfig)
	}
	
	func applicationWillResignActive(application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(application: UIApplication) {
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


}

