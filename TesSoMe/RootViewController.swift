//
//  RootViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/13.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import Social

class RootViewController: UITabBarController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		let chooseTopicBtn = UIBarButtonItem(image: UIImage(named: "menu_icon"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showTopicMenu"))
		let newPostBtn = UIBarButtonItem(image: UIImage(named: "post_icon"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showPostView"))

		let unreadMessageLabelAppearance = [NSForegroundColorAttributeName: UIColor.globalTintColor()]

		for viewController in self.viewControllers! as [UINavigationController] {
			let topViewController = viewController.viewControllers?[0] as UIViewController
			topViewController.navigationItem.leftBarButtonItem = chooseTopicBtn
			topViewController.navigationItem.rightBarButtonItem = newPostBtn
			viewController.tabBarItem.setTitleTextAttributes(unreadMessageLabelAppearance, forState: .Normal)
		}
		
		let apiManager = TessoApiManager()
		apiManager.checkConnectionAndReSignIn(appDelegate.usernameOfTesSoMe!, password: appDelegate.passwordOfTesSoMe!)
		
		self.tabBar.tintColor = UIColor.globalTintColor()
	}

	func showTopicMenu() {
		appDelegate.frostedViewController!.presentMenuViewController()
	}
	
	func showPostView() {
		let topicMenuViewController = appDelegate.frostedViewController?.menuViewController as TopicMenuViewController
		let topicid = topicMenuViewController.currentTopic
		
		let storyboard = UIStoryboard(name: "PostMessage", bundle: nil)
		var postNavigationController: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("PostNavigation") as UINavigationController
		let postViewController = postNavigationController.viewControllers.first as PostMainViewController
		postViewController.topicid = topicid
		self.presentViewController(postNavigationController, animated: true, completion: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

}
