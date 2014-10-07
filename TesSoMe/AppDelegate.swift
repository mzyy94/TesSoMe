//
//  AppDelegate.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/12.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import Accelerate
import AudioToolbox

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
		
		if !ud.boolForKey("initializedNotification") {
			initNotification(application)
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
			var parameter: [String: String] = [:]
			if let query = url.query {
				for q in query.componentsSeparatedByString("&") {
					let element = q.componentsSeparatedByString("=")
					if element.count == 2 {
						let key = element[0].stringByRemovingPercentEncoding!
						let value = element[1].stringByRemovingPercentEncoding!
						parameter.updateValue(value, forKey: key)
					}
				}
				
				if parameter["text"] == nil {
					postViewController.preparedText = ""
				} else {
					postViewController.preparedText = parameter["text"]!
				}
				postViewController.topicid = parameter["topic"]?.toInt()
			}
			
			self.window?.rootViewController!.presentViewController(postNavigationController, animated: true, completion: nil)
			
		case "user":
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
			
			self.window?.rootViewController!.presentViewController(userViewController, animated: true, completion: nil)


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
		defaultConfig.setObject(false, forKey: "imagePreview")
		defaultConfig.setObject(false, forKey: "viaSignature")
		defaultConfig.setObject(true, forKey: "backgroundNotification")
		defaultConfig.setObject(true, forKey: "vibratingNotification")
		defaultConfig.setObject(true, forKey: "streaming")
		defaultConfig.setObject(10.0, forKey: "interval")
		defaultConfig.setObject(false, forKey: "debug")
		defaultConfig.setObject(false, forKey: "detailNetwork")
		ud.registerDefaults(defaultConfig)
	}
	
	func initNotification(application: UIApplication) {
		let replyAction = UIMutableUserNotificationAction()
		replyAction.identifier = "TESSOME_REPLY_NOTIFICATION"
		replyAction.title = NSLocalizedString("Reply", comment: "Reply")
		replyAction.activationMode = .Foreground
		replyAction.destructive = true
		replyAction.authenticationRequired = false
		
		let okAction = UIMutableUserNotificationAction()
		okAction.identifier = "TESSOME_OPEN_NOTIFICATION"
		okAction.title = NSLocalizedString("Open", comment: "Open timeline")
		okAction.activationMode = .Foreground
		okAction.destructive = false
		okAction.authenticationRequired = false
		
		let replyCategory = UIMutableUserNotificationCategory()
		replyCategory.identifier = "REPLY_CATEGORY"
		replyCategory.setActions([replyAction, okAction], forContext: .Default)
		
		let classAction = UIMutableUserNotificationAction()
		classAction.identifier = "TESSOME_CLASS_NOTIFICATION"
		classAction.title = NSLocalizedString("Open", comment: "Open class")
		classAction.activationMode = .Foreground
		classAction.destructive = false
		classAction.authenticationRequired = false
		
		let classCategory = UIMutableUserNotificationCategory()
		classCategory.identifier = "CLASS_CATEGORY"
		classCategory.setActions([classAction], forContext: .Default)
		
		let notificationCategories = NSSet(objects: replyCategory, classCategory)
		
		let notificationSettings = UIUserNotificationSettings(forTypes:  .Badge | .Sound | .Alert, categories: notificationCategories)
		application.registerUserNotificationSettings(notificationSettings)
		
		ud.setBool(true, forKey: "initializedNotification")
		ud.synchronize()
	}
	
	func notifyMessage(message: String, from username: String, statusid: Int, topicid: Int) {
		let notificationTextFormat = NSLocalizedString("From @%@: %@", comment: "notification text format")
		let localNotification = UILocalNotification()
		localNotification.fireDate = NSDate()
		localNotification.timeZone = NSTimeZone.defaultTimeZone()
		localNotification.soundName = UILocalNotificationDefaultSoundName
		localNotification.category = "REPLY_CATEGORY"
		localNotification.alertAction = "Reply Action"
		localNotification.alertBody = NSString(format: notificationTextFormat, username, message)
		localNotification.userInfo = ["username": username, "message": message, "statusid": statusid, "topicid": topicid]
		UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
	}
	
	func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
		if notification.category! == "REPLY_CATEGORY" {
			let userInfo = NSDictionary(dictionary: notification.userInfo!)
			let username = userInfo["username"] as String!
			let message = userInfo["message"] as String!
			let statusId = userInfo["statusid"] as Int!
			let topicid = userInfo["topicid"] as Int!
			let titleFormat = NSLocalizedString("Reply from @%@", comment: "reply notification title format")
			let text = ">\(statusId)(@\(username)) "

			let notificationView = MPGNotification(title: NSString(format: titleFormat, username), subtitle: message, backgroundColor: UIColor(red: 0.3, green: 0.3, blue: 1.0, alpha: 1.0), iconImage: UIImage(named: "comment_icon"))
			notificationView.duration = 5.0
			notificationView.animationType = .Drop
			notificationView.setButtonConfiguration(.OneButton, withButtonTitles: [NSLocalizedString("Reply", comment: "Reply")])
			notificationView.swipeToDismissEnabled = false
			notificationView.buttonHandler = {
				notification, buttonIndex in
				if buttonIndex == notification.firstButton.tag {
					UIApplication.sharedApplication().openURL(NSURL(string: "tesso://post/?topic=\(topicid)&text=\(text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"))
				}
			}
			notificationView.show()
			UIApplication.sharedApplication().cancelLocalNotification(notification)
		}
		
		if ud.boolForKey("vibratingNotification") {
			AudioServicesPlaySystemSound(UInt32(kSystemSoundID_Vibrate))
		}
		
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

