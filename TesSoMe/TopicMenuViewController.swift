//
//  TopicMenuViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TopicMenuViewController: UITableViewController {

    @IBOutlet weak var userIconBtn: UIButton!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var lebelLabel: UILabel!

	var topics: [NSDictionary] = []
	
    @IBAction func userIconBtnTapped(sender: AnyObject) {
		showSettingView()
    }
    
	func showSettingView() {
		let storyboard = UIStoryboard(name: "Settings", bundle: nil)
		var settingViewController: UINavigationController = storyboard.instantiateViewControllerWithIdentifier("SettingsNavigation") as UINavigationController
		settingViewController.viewControllers.first?.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("closeSettingView"))
		self.presentViewController(settingViewController, animated: true, completion: nil)
	}
	
	func closeSettingView() {
		self.presentedViewController!.dismissViewControllerAnimated(true, completion: nil)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.userIconBtn.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIconBtn.layer.borderWidth = 1.0
		self.userIconBtn.layer.cornerRadius = 4.0
		self.userIconBtn.clipsToBounds = true

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // Return the number of topics
        return topics.count
    }
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		return 68.0
	}

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TopicCell", forIndexPath: indexPath) as TopicCell
        // Edit cell
		let topic = topics[indexPath.row]
		cell.topicTitleLabel.text = (topic["title"] as String)
		cell.latestMessageLabel.text = (topic["message"] as String)
//		cell.userIcon.image = UIImage(data: NSData(contentsOfURL: NSURL(string: "https://tesso.pw/img/icons/" + (topic["username"] as String) + ".png")))
		cell.userIcon.sd_setImageWithURL(NSURL(string: "https://tesso.pw/img/icons/" + (topic["username"] as String) + ".png"))
		cell.topicNumLabel.text = String((topic["id"] as String).toInt()! + 99)
		println(cell.topicNumLabel.text)
		
        return cell
    }
	
	override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Topic", comment: "Topic")
	}

}
