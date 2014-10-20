//
//  SettingViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	
	
	// Setting root
	@IBOutlet weak var notificationCell: UITableViewCell!
	@IBOutlet weak var streamingCell: UITableViewCell!
	@IBOutlet weak var developerCell: UITableViewCell!
	@IBOutlet weak var versionAndCopyrightLabel: UILabel!
	
	func initRootSetting() {
		let enabled = NSLocalizedString("Enabled", comment: "Eanbled")
		let disabled = NSLocalizedString("Disabled", comment: "Disabled")
		
		if ud.boolForKey("backgroundNotification") {
			notificationCell.detailTextLabel?.text = enabled
		} else {
			notificationCell.detailTextLabel?.text = disabled
		}
		
		if ud.boolForKey("streaming") {
			streamingCell.detailTextLabel?.text = enabled
		} else {
			streamingCell.detailTextLabel?.text = disabled
		}
		
		if ud.boolForKey("debug") || ud.boolForKey("detailNetwork") {
			developerCell.detailTextLabel?.text = enabled
		} else {
			developerCell.detailTextLabel?.text = disabled
		}
		
		let currentVersion = (NSBundle.mainBundle().infoDictionary["CFBundleShortVersionString"] as NSString).doubleValue

		versionAndCopyrightLabel.text = "©2014 mzyy94. TesSoMe \(currentVersion)"
		
	}
	
	
	/* ================
	===   General   ===
	================ */

	// Appearance
	override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		if tableView.restorationIdentifier == nil {
			return
		}
		switch tableView.restorationIdentifier! {
		case "Appearance":
			if indexPath.section == 1 { // timestamp
				for i in 0..<tableView.numberOfRowsInSection(indexPath.section) {
					tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: indexPath.section))?.accessoryType = .None
				}
				let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
				selectedCell.accessoryType = .Checkmark
				selectedCell.selected = false
				
				let isRelative = !Bool(indexPath.row)
				ud.setBool(isRelative, forKey: "relativeTimestamp")
				let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as TimelineMessageCell
				cell.updateTimestamp(relative: isRelative)
			}
		case "RootSetting":
			if indexPath == NSIndexPath(forRow: 0, inSection: 3) { // Danger
				let confirmationText = NSLocalizedString("Do you really want to delete settings and data?", comment: "Alert confirmation text")
				let alertController = UIAlertController(title: confirmationText, message: nil, preferredStyle: .Alert)
				
				let setClassNotificationAction = UIAlertAction(title: NSLocalizedString("YES", comment: "YES on AlertView"), style: .Destructive, handler:
					{ action in
						let serviceName = "TesSoMe"
						for account in SSKeychain.allAccounts() {
							let username = account["acct"]
							SSKeychain.deletePasswordForService(serviceName, account: username as String)
						}
						let domain = NSBundle.mainBundle().bundleIdentifier
						NSUserDefaults.standardUserDefaults().removePersistentDomainForName(domain!)
						
						let apiManager = TessoApiManager()
						apiManager.signOut(onSuccess: nil, onFailure: nil)
						
						let shutdonwText = NSLocalizedString("Please restart TesSoMe immediately.", comment: "Shutdown text")
						let shutdownAlertController = UIAlertController(title: shutdonwText, message: nil, preferredStyle: .Alert)
						let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Cancel, handler:
							{ action in
								exit(1)
							}
						)
						shutdownAlertController.addAction(okAction)
						self.presentViewController(shutdownAlertController, animated: true, completion: nil)
					}
				)
				alertController.addAction(setClassNotificationAction)
				
				let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
				alertController.addAction(cancelAction)
				
				self.presentViewController(alertController, animated: true, completion: nil)
			} else if indexPath == NSIndexPath(forRow: 0, inSection: 4) { // About mzyy94
				let url = NSURL(string: "http://www.amazon.co.jp/registry/wishlist/1HE845FB3VZWO")
				let webKitViewController = WebKitViewController()
				webKitViewController.url = url
				self.navigationController?.pushViewController(webKitViewController, animated: true)
			}

		default:
			return
		}
	}
	
	@IBOutlet weak var previewCell: UITableViewCell!
	@IBOutlet weak var relativeCell: UITableViewCell!
	@IBOutlet weak var absoluteCell: UITableViewCell!
	@IBOutlet weak var fontSizeSlider: UISlider!
	@IBOutlet weak var badgeSwitch: UISwitch!
	@IBOutlet weak var replyUserIconSwitch: UISwitch!
	@IBOutlet weak var imagePreviewSwitch: UISwitch!
	
	@IBAction func fontSizeSliderChanged(sender: UISlider) {
		sender.value = Float(Int(sender.value))
		ud.setFloat(sender.value, forKey: "fontSize")
		let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as TimelineMessageCell

		if ud.boolForKey("replyIcon") {
			let postedDate = NSDate(timeIntervalSinceNow: -557.0)
			let data = NSDictionary(dictionary: ["statusid": "1", "nickname": "", "username": "", "unixtime": "1", "topicid": "1", "type": "0", "data": ">999999(@eula) こんばんは〜 Eulaちゃんだよ！\nどうしたのかな？\n    "])
			let cellData = TesSoMeData(data: data)
			let attributedText = cellData.replaceUsernameToIcon(CGFloat(sender.value))
			
			cell.messageTextView.attributedText = attributedText
		}
		
		cell.messageTextView.font = UIFont.systemFontOfSize(CGFloat(sender.value))
	}
	
	@IBAction func badgeSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "badge")
		let cell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as TimelineMessageCell
		cell.viaTesSoMeBadge.hidden = !sender.on
	}
	@IBAction func replyUserIconSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "replyIcon")
		self.tableView.reloadData()
	}
	
	@IBAction func imagePreviewSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "imagePreview")
	}
	
	func initAppearanceSetting() {
		let fontSize = ud.floatForKey("fontSize")
		fontSizeSlider.value = fontSize
		
		let isRelative = ud.boolForKey("relativeTimestamp")
		if isRelative {
			relativeCell.accessoryType = .Checkmark
		} else {
			absoluteCell.accessoryType = .Checkmark
		}
		
		badgeSwitch.on = ud.boolForKey("badge")
		imagePreviewSwitch.on = ud.boolForKey("imagePreview")
		replyUserIconSwitch.on = ud.boolForKey("replyIcon")
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		if tableView.restorationIdentifier != nil && tableView.restorationIdentifier == "Appearance" && indexPath == NSIndexPath(forRow: 0, inSection: 0) {
			let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
			self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")

			var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: NSIndexPath(forRow: 0, inSection: 0)) as TimelineMessageCell
			let postedDate = NSDate(timeIntervalSinceNow: -557.0)
			let data = NSDictionary(dictionary: ["statusid": "99999", "nickname": "Eula", "username": "eula", "unixtime": "\(Int(postedDate.timeIntervalSince1970))", "topicid": "1", "type": "0", "data": ">999999(@eula) こんばんは〜 Eulaちゃんだよ！\nどうしたのかな？\n    "])
			let cellData = TesSoMeData(data: data)
			cellData.setDataToCell(&cell, withFontSize: CGFloat(ud.floatForKey("fontSize")), withBadge: ud.boolForKey("badge"), withImagePreview: ud.boolForKey("imagePreview"), withReplyIcon: ud.boolForKey("replyIcon"))
			cell.updateTimestamp(relative: ud.boolForKey("relativeTimestamp"))
			
			return cell
		}
		return super.tableView(tableView, cellForRowAtIndexPath: indexPath)
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if tableView.restorationIdentifier != nil && tableView.restorationIdentifier == "Appearance" && section == 0 {
			return 1
		}
		return super.tableView(tableView, numberOfRowsInSection: section)
	}
	
	override func tableView(tableView: UITableView, indentationLevelForRowAtIndexPath indexPath: NSIndexPath) -> Int {
		return super.tableView(tableView, indentationLevelForRowAtIndexPath: indexPath)
	}
	
	override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
		if tableView.restorationIdentifier != nil && tableView.restorationIdentifier == "Appearance" && indexPath == NSIndexPath(forRow: 0, inSection: 0) {
			return 100.0
		}
		return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
	}
	
	// Post
	@IBOutlet weak var viaSignatureSwitch: UISwitch!
	
	@IBAction func viaSignatureSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "viaSignature")
	}
	
	func initPostSetting() {
		viaSignatureSwitch.on = ud.boolForKey("viaSignature")
	}
	
	
	// Notification
	@IBOutlet weak var backgroundNotificationSwitch: UISwitch!
	@IBOutlet weak var vibratingNotificationSwitch: UISwitch!
	
	@IBAction func backgroundNotificationSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "backgroundNotification")
	}
	
	@IBAction func vibratingNotificationSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "vibratingNotification")
	}
	
	func initNotificationSetting() {
		backgroundNotificationSwitch.on = ud.boolForKey("backgroundNotification")
		vibratingNotificationSwitch.on = ud.boolForKey("vibratingNotification")
	}
	
	
	// Streaming
	@IBOutlet weak var streamingSwitch: UISwitch!
	@IBOutlet weak var intervalSlider: UISlider!
	@IBOutlet weak var intervalLabel: UILabel!
	
	let intervalLabelFormat = NSLocalizedString("%d Sec", comment: "Interval seconds format")
	
	@IBAction func streamingSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "streaming")
		intervalSlider.enabled = sender.on
	}
	
	@IBAction func intervalSliderChanged(sender: UISlider) {
		let interval = Int(sender.value)
		sender.value = Float(interval)
		intervalLabel.text = NSString(format: intervalLabelFormat, interval)
		ud.setFloat(sender.value, forKey: "interval")
	}
	
	func initStreamingSetting() {
		streamingSwitch.on = ud.boolForKey("streaming")
		if !streamingSwitch.on {
			intervalSlider.enabled = false
		}
		intervalSlider.value = ud.floatForKey("interval")
		intervalLabel.text = NSString(format: intervalLabelFormat, Int(ud.floatForKey("interval")))
	}
	
	
	/* ================
	===   Account   ===
	================ */
	
	// Account
	@IBOutlet weak var userIdField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var signInBtn: UIButton!
	
	@IBAction func signInBtnPressed() {
		let apiMgr = TessoApiManager()
		apiMgr.signIn(username: userIdField.text!, password: passwordField.text!, onSuccess:
			{
				var alertController = UIAlertController(title: NSLocalizedString("Success", comment: "Success on AlertView"), message: NSLocalizedString("You have signed in.", comment: "You have signed in."), preferredStyle: .Alert)
				
				let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler: nil)
				alertController.addAction(okAction)

				// save password
				let serviceName = "TesSoMe"
				SSKeychain.setPassword(self.passwordField.text!, forService: serviceName, account: self.userIdField.text!)
				
				// close keyboard
				self.userIdField.resignFirstResponder()
				self.passwordField.resignFirstResponder()
				
				self.presentViewController(alertController, animated: true, completion: nil)
			}
			, onFailure:
			{ err in
				var alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error on AlertView"), message: err.localizedDescription, preferredStyle: .Alert)
				
				let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler: nil)
				alertController.addAction(okAction)
				
				self.presentViewController(alertController, animated: true, completion: nil)
		})
	}

	func initAccountSetting() {
		self.userIdField.text = appDelegate.usernameOfTesSoMe
		self.passwordField.text = appDelegate.passwordOfTesSoMe
	}
	
	/* ================
	===  Developer  ===
	================ */
	
	// Developer mode
	
	@IBOutlet weak var debugLogSwitch: UISwitch!
	@IBOutlet weak var detailNetworkSwitch: UISwitch!

	@IBAction func debugLogSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "debug")
	}
	
	@IBAction func detailNetworkSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "detailNetwork")
	}
	
	func initDeveloperSetting() {
		debugLogSwitch.on = ud.boolForKey("debug")
		detailNetworkSwitch.on = ud.boolForKey("detailNetwork")
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		
		if tableView.restorationIdentifier == nil {
			return
		}
		switch tableView.restorationIdentifier! {
		case "Appearance":
			initAppearanceSetting()
		case "Post":
			initPostSetting()
		case "Notification":
			initNotificationSetting()
		case "Streaming":
			initStreamingSetting()
		case "Account":
			initAccountSetting()
		case "Developer":
			initDeveloperSetting()
		default:
			initRootSetting()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false

		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}
	
	override func viewWillDisappear(animated: Bool) {
		ud.synchronize()
		
		switch tableView.restorationIdentifier! {
		case "Streaming":
			let timelineViewController = appDelegate.frostedViewController?.contentViewController.childViewControllers.first?.childViewControllers.first as TimelineViewController
			timelineViewController.setUpdateTimelineFetchTimer()
		default:
			false // Add more functions
		}
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
