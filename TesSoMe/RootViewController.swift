//
//  RootViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/13.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class RootViewController: UITabBarController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	let apiManager = TessoApiManager()

	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		let chooseTopicBtn = UIBarButtonItem(image: UIImage(named: "menu_icon"), style: UIBarButtonItemStyle.Plain, target: self, action: Selector("showTopicMenu"))

		for viewController in self.viewControllers! as [UINavigationController] {
			let topViewController: UIViewController = viewController.viewControllers?[0] as UIViewController
			topViewController.navigationItem.leftBarButtonItem = chooseTopicBtn
		}
		
		self.tabBar.tintColor = UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 1.0)
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.getSelfInfo()
			self.getTopic()
		})
	}

	func showTopicMenu() {
		appDelegate.frostedViewController!.presentMenuViewController()
	}
	
	func getSelfInfo() {
		if appDelegate.usernameOfTesSoMe != nil {
			let topicViewController = self.appDelegate.frostedViewController?.menuViewController as TopicMenuViewController
			topicViewController.userIconBtn.sd_setBackgroundImageWithURL(NSURL(string: "https://tesso.pw/img/icons/" + appDelegate.usernameOfTesSoMe! + ".png"), forState: .Normal)

			apiManager.getProfile(username: appDelegate.usernameOfTesSoMe!, withTimeline: false, onSuccess:
				{ data in
					let userinfo = (TesSoMeData.dataFromResponce(data) as NSArray)[0] as NSDictionary
					topicViewController.usernameLabel.text = "@" + (userinfo["username"] as String)
					topicViewController.nicknameLabel.text = userinfo["nickname"] as? String
					topicViewController.lebelLabel.text = "Lv. " + (userinfo["lv"] as String)
				}
				, onFailure: nil
			)
		}
	}

	func getTopic() {
		apiManager.getTopic(onSuccess:
			{ data in
				let topicViewController = self.appDelegate.frostedViewController?.menuViewController as TopicMenuViewController
				let topics = TesSoMeData.dataFromResponce(data)
				let latestMsgs = TesSoMeData.tlFromResponce(data)
				var topicsWithMsgs:[NSMutableDictionary] = []
				
				for (index, topic) in enumerate(topics as [NSDictionary]) {
					let mutableDic = NSMutableDictionary()
					let latestMsg = latestMsgs[index] as NSDictionary
					let converter = HTMLEntityConverter()
					mutableDic.setValuesForKeysWithDictionary(topic)
					mutableDic.setValue(mutableDic["data"] as String, forKeyPath: "title")
					mutableDic.setValuesForKeysWithDictionary(latestMsg)
					mutableDic.setValue(converter.decodeXML(mutableDic["data"] as String), forKeyPath: "message")
					
					topicsWithMsgs.append(mutableDic)
				}
				
				var selectInitialTopic = false
				if topicViewController.topics.count == 0 {
					selectInitialTopic = true
				}
				
				topicViewController.topics = topicsWithMsgs
				topicViewController.tableView.reloadData()
				
				if selectInitialTopic {
					topicViewController.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))?.selected = true
				}
				
			}
			, onFailure: nil
		)
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
