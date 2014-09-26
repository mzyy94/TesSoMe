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
			let topViewController: UIViewController = viewController.viewControllers?[0] as UIViewController
			topViewController.navigationItem.leftBarButtonItem = chooseTopicBtn
			topViewController.navigationItem.rightBarButtonItem = newPostBtn
			viewController.tabBarItem.setTitleTextAttributes(unreadMessageLabelAppearance, forState: .Normal)
		}
		
		self.tabBar.tintColor = UIColor.globalTintColor()
	}

	func showTopicMenu() {
		appDelegate.frostedViewController!.presentMenuViewController()
	}
	
	func showPostView() {
		let storyboard = UIStoryboard(name: "PostMessage", bundle: nil)
		var postViewController: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("PostNavigation") as UINavigationController
		self.presentViewController(postViewController, animated: true, completion: nil)
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

	/*
	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
		// Get the new view controller using segue.destinationViewController.
		// Pass the selected object to the new view controller.
	}
	*/

}
