//
//  UserViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/02.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class UserViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
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
		
		if username == "" {
			username = appDelegate.usernameOfTesSoMe!
		}

		if username == appDelegate.usernameOfTesSoMe {
			let settingUserdataBtn = UIBarButtonItem(image: UIImage(named: "setting_icon"), style: .Plain, target: self, action: Selector("settingUserdata"))
			self.navigationItem.rightBarButtonItem = settingUserdataBtn
		} else {
			let addLabelBtn = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("addLabelToUser"))
			self.navigationItem.rightBarButtonItem = addLabelBtn
		}

		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.informationTableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.informationTableView.estimatedRowHeight = 90.5
		self.informationTableView.rowHeight = UITableViewAutomaticDimension
		
		self.informationTableView.delegate = self
		self.informationTableView.dataSource = self
		
		self.profileTextView.delegate = self
		
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
					self.messages.append(TesSoMeData(data: post, isTopicIdVisible: true))
				}
				self.nicknameLabel.text = nickname
				self.levelLabel.text = "Lv. \(level)"
				self.profileTextView.attributedText = TesSoMeData.convertAttributedProfile(userInfo, size: CGFloat(self.ud.floatForKey("fontSize")))
			}
			, onFailure:
			{ err in
				let notification = MPGNotification(title: NSLocalizedString("Can not get user infomation", comment: "Can not get user information"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
				notification.duration = 5.0
				notification.animationType = .Drop
				notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
				notification.swipeToDismissEnabled = false
				notification.show()
				
				self.navigationController?.popViewControllerAnimated(true)
		})
		
    }
	
	var addLabelAction: UIAlertAction! = nil
	
	func addLabelToUser() {
		let alertController = UIAlertController(title: NSLocalizedString("Add Label", comment: "Add Label on AlertView"), message: NSLocalizedString("Please type new label (max. 256 characters).", comment: "Please type new label (max. 256 characters)."), preferredStyle: .Alert)

		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel) {
			action in
			NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alertController.textFields?.first)
		}
		alertController.addAction(cancelAction)
		
		self.addLabelAction = UIAlertAction(title: NSLocalizedString("Add", comment: "Add on AlertView"), style: .Default) {
			action in
			
			let textField = alertController.textFields?.first as UITextField
			let newLabel = textField.text
			
			self.apiManager.addTitle(username: self.username, title: newLabel, onSuccess:
				{ data in
					self.apiManager.getProfile(username: self.username, withTitle: true, withTimeline: true, onSuccess:
						{ data in
							let userdata = (data["data"] as [NSDictionary]).first!
							let userInfo = userdata["data"] as String!
							let nickname = userdata["nickname"] as String!
							let level = userdata["lv"] as String!
							self.labels = userdata["label"] as [NSDictionary]!
							self.nicknameLabel.text = nickname
							self.levelLabel.text = "Lv. \(level)"
							self.profileTextView.attributedText = TesSoMeData.convertAttributedProfile(userInfo, size: CGFloat(self.ud.floatForKey("fontSize")))
							self.informationTableView.reloadData()
						}
						, onFailure: nil)
					

				}, onFailure:
				{ err in
					let notification = MPGNotification(title: NSLocalizedString("Can not add new label", comment: "Can not add new label"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
					notification.duration = 5.0
					notification.animationType = .Drop
					notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
					notification.swipeToDismissEnabled = false
					notification.show()
			})
			NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alertController.textFields?.first)
		}
		alertController.addAction(self.addLabelAction)
		
		alertController.addTextFieldWithConfigurationHandler(
			{ textField in
				NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleTextFieldTextDidChangeNotification:"), name: UITextFieldTextDidChangeNotification, object: textField)
			}
		)
		
		self.presentViewController(alertController, animated: true, completion: nil)
		

	}
	
	func settingUserdata() {
		let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
		
		let addLabel = UIAlertAction(title: NSLocalizedString("Add Label", comment: "Add Label on AlertView"), style: .Default)
			{ action in
				self.addLabelToUser()
		}
		alertController.addAction(addLabel)
		
		let changeNickname = UIAlertAction(title: NSLocalizedString("Change Nickname", comment: "Change Nickname on AlertView"), style: .Default)
			{ action in
				self.changeNickname()
		}
		// MEMO: NO API AVAILABLE
		//alertController.addAction(changeNickname)
		
		let editProfile = UIAlertAction(title: NSLocalizedString("Edit Profile", comment: "Edit Profile on AlertView"), style: .Default)
			{ action in
				self.editProfile()
		}
		// MEMO: NO API AVAILABLE
		//alertController.addAction(editProfile)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		

		self.presentViewController(alertController, animated: true, completion: nil)
		
	}

	func changeNickname() {
		let alertController = UIAlertController(title: NSLocalizedString("Change Nickname", comment: "Change Nickname on AlertView"), message: NSLocalizedString("Please type new nickname.", comment: "Please type new nickname."), preferredStyle: .Alert)

		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		let changeNicknameAction = UIAlertAction(title: NSLocalizedString("Change", comment: "Change on AlertView"), style: .Default) {
			action in
			
			let textField = alertController.textFields?.first as UITextField
			let newNickname = textField.text
			
			self.apiManager.updateProfile(nickname: newNickname, onSuccess:
				{ data in
					self.nicknameLabel.text = newNickname
				}, onFailure:
				{ err in
					let notification = MPGNotification(title: NSLocalizedString("Can not change nickname", comment: "Can not change nickname"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
					notification.duration = 5.0
					notification.animationType = .Drop
					notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
					notification.swipeToDismissEnabled = false
					notification.show()
			})
		}
		alertController.addAction(changeNicknameAction)
		
		alertController.addTextFieldWithConfigurationHandler(
			{ textField in
				textField.placeholder = NSLocalizedString("New Nickname", comment: "New Nickname on AlertView")
			}
		)
		
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	
	func editProfile() {
		let alertController = UIAlertController(title: NSLocalizedString("Edit Profile", comment: "Edit Profile on AlertView"), message: NSLocalizedString("Please type new profile.", comment: "Please type new profile."), preferredStyle: .Alert)

		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		let editProfileAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default) {
			action in
			
			let textField = alertController.textFields?.first as UITextField
			let newProfile = textField.text
			
			self.apiManager.updateProfile(profile: newProfile, onSuccess:
				{ data in
					self.profileTextView.text = newProfile
				}, onFailure:
				{ err in
					let notification = MPGNotification(title: NSLocalizedString("Can not edit profile", comment: "Can not edit profile"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
					notification.duration = 5.0
					notification.animationType = .Drop
					notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
					notification.swipeToDismissEnabled = false
					notification.show()
			})
		}
		alertController.addAction(editProfileAction)
		
		alertController.addTextFieldWithConfigurationHandler(nil)
		
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	
	func handleTextFieldTextDidChangeNotification(notification: NSNotification) {
		let textField = notification.object as UITextField
		let newLabel = textField.text
		if newLabel != nil && textField.text.utf16Count < 256 {
			addLabelAction.enabled = true
		} else {
			addLabelAction.enabled = false
		}
	}
	
	
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
			let converter = HTMLEntityConverter()
			cell.labelLabel.text = converter.decodeXML(data["data"] as String!)
			
			return cell
		case 2:
			var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as TimelineMessageCell
			let data = messages[indexPath.row]
			// Configure the cell...
			data.setDataToCell(&cell, withFontSize: CGFloat(ud.floatForKey("fontSize")), withBadge: true, withImagePreview: ud.boolForKey("imagePreview"), withReplyIcon: ud.boolForKey("replyIcon"))
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

	func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
		let webKitViewController = WebKitViewController()
		webKitViewController.url = URL
		
		self.navigationController?.pushViewController(webKitViewController, animated: true)
		return false
	}
	
	func segmentedControlValueChanged(sender: HMSegmentedControl) {
        self.informationTableView.reloadData()
	}
	
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	

}
