//
//  UserViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/02.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let apiManager = TessoApiManager()
	let ud = NSUserDefaults()

	var username = ""
	var labels: [NSDictionary] = []
	var messages: [TesSoMeData] = []
	
	var segmentedControl: HMSegmentedControl! = nil
	
	@IBOutlet weak var userIcon: UIImageView!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var levelLabel: UILabel!
	@IBOutlet weak var segmentedControlArea: UIView!
	@IBOutlet weak var informationTableView: UITableView!
	@IBOutlet weak var profileTextView: UITextView!
	@IBOutlet weak var profileView: UIView!
	
	@IBAction func WebIconBtnPressed() {
		let webKitViewController = WebKitViewController()
		webKitViewController.url = NSURL(string: "https://tesso.pw/mem/\(username)/")
		
		self.navigationController?.pushViewController(webKitViewController, animated: true)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.informationTableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.informationTableView.estimatedRowHeight = 90.5
		self.informationTableView.rowHeight = UITableViewAutomaticDimension
		
		self.informationTableView.delegate = self
		self.informationTableView.dataSource = self
		
		let profile = NSLocalizedString("Profile", comment: "Profile at segmented control")
		let label = NSLocalizedString("Label", comment: "Label at segmented control")
		let post = NSLocalizedString("Recently Post", comment: "Recently Post at segmented control")
		let items = [profile, label, post]
		
		segmentedControl = HMSegmentedControl(sectionTitles: items)
		
		segmentedControl.frame = CGRectMake(0, 0, self.view.frame.width, 32)
		segmentedControl.selectionIndicatorHeight = 4.0
		segmentedControl.backgroundColor = UIColor.whiteColor()
		segmentedControl.textColor = UIColor.lightGrayColor()
		segmentedControl.selectedTextColor = UIColor.globalTintColor()
		segmentedControl.selectionIndicatorColor = UIColor.globalTintColor()
		segmentedControl.selectionStyle = HMSegmentedControlSelectionStyleBox
		segmentedControl.selectedSegmentIndex = 0
		segmentedControl.selectionIndicatorLocation = HMSegmentedControlSelectionIndicatorLocationDown
		segmentedControl.shouldAnimateUserSelection = true
		
		segmentedControl.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		segmentedControl.addTarget(self, action: Selector("segmentedControlValueChanged:"), forControlEvents: .ValueChanged)
		
		self.segmentedControlArea.addSubview(segmentedControl)
		
		for constraintAttribute: NSLayoutAttribute in [.Bottom, .Top, .Right, .Left] {
			self.view.addConstraint(NSLayoutConstraint(item: segmentedControl, attribute: constraintAttribute, relatedBy: .Equal, toItem: self.segmentedControlArea, attribute: constraintAttribute, multiplier: 1.0, constant: 0))
		}
		
		self.userIcon.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIcon.layer.borderWidth = 1.0
		self.userIcon.layer.cornerRadius = 4.0
		self.userIcon.clipsToBounds = true
		
		if username == "" {
			username = appDelegate.usernameOfTesSoMe!
		}
		
		self.usernameLabel.text = "@\(username)"
		self.navigationItem.title = "@\(username)"
		self.userIcon.sd_setImageWithURL(NSURL(string: "https://tesso.pw/img/icons/\(username).png"))
		
		apiManager.getProfile(username: username, withTitle: true, withTimeline: true, onSuccess:
			{ data in
				let userdata = (data["data"] as [NSDictionary]).first!
				let userInfo = userdata["data"] as String!
				let id = userdata["id"] as String!
				let nickname = userdata["nickname"] as String!
				let level = userdata["lv"] as String!
				self.labels = userdata["label"] as [NSDictionary]!
				let timeline = TesSoMeData.tlFromResponce(data) as [NSDictionary]
				for post in timeline {
					self.messages.append(TesSoMeData(data: post))
				}
				self.nicknameLabel.text = nickname
				self.levelLabel.text = "Lv. \(level)"
				self.profileTextView.attributedText = TesSoMeData.convertAttributedProfile(userInfo)
			}
			, onFailure:
			{ err in
				let notification = MPGNotification(title: NSLocalizedString("Can not get user infomation", comment: "Can not get user information"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
				notification.duration = 5.0
				notification.animationType = .Drop
				notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
				notification.show()
				
				self.navigationController?.popViewControllerAnimated(true)
		})
		
    }

	/*
	tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath!) -> Bool {
	func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath!) {
	func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
	*/
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		switch segmentedControl.selectedSegmentIndex {
		case 1:
            var cell = tableView.dequeueReusableCellWithIdentifier("LabelCell", forIndexPath: indexPath) as LabelCell
            let data = labels[indexPath.row]
            
            cell.labeledUsername = data["username"] as String!
            cell.userIconBtn.sd_setBackgroundImageWithURL(NSURL(string: "https://tesso.pw/img/icons/\(cell.labeledUsername).png"), forState: .Normal)
            cell.labelLabel.text = data["data"] as String!
			
			return cell
		case 2:
			var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as TimelineMessageCell
			let data = messages[indexPath.row]
			// Configure the cell...
			data.setDataToCell(&cell, withFontSize: CGFloat(ud.floatForKey("fontSize")), withBadge: true)
			cell.updateTimestamp(relative: false)
			return cell
		default:
			return UITableViewCell()
		}
	}
	
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.segmentedControl.selectedSegmentIndex {
        case 0:
			self.profileView.hidden = false
            return 0
        case 1:
			self.profileView.hidden = true
            return labels.count
        case 2:
			self.profileView.hidden = true
            return messages.count
        default:
            return 0
        }
    }
    
	func segmentedControlValueChanged(sender: HMSegmentedControl) {
        self.informationTableView.reloadData()
	}
	
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	

}
