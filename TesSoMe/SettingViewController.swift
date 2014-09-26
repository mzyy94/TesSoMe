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
            if indexPath.section == 0 { // timestamp
                for i in 0..<tableView.numberOfRowsInSection(indexPath.section) {
                    tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: indexPath.section))?.accessoryType = .None
                }
                let selectedCell = tableView.cellForRowAtIndexPath(indexPath)!
                selectedCell.accessoryType = .Checkmark
                selectedCell.selected = false
				
				if indexPath.row == 0 { // Relative
					ud.setBool(true, forKey: "relativeTimestamp")
				} else { // Absolute
					ud.setBool(false, forKey: "relativeTimestamp")
				}
            }
        default:
            return
        }
    }
	
	@IBOutlet weak var relativeCell: UITableViewCell!
	@IBOutlet weak var absoluteCell: UITableViewCell!
	@IBOutlet weak var fontSizeSlider: UISlider!
	
	@IBAction func fontSizeSliderChanged(sender: UISlider) {
		sender.value = Float(Int(sender.value))
		ud.setFloat(sender.value, forKey: "fontSize")
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
	@IBOutlet weak var wifiOnlySwitch: UISwitch!
	@IBOutlet weak var intervalSlider: UISlider!
	@IBOutlet weak var intervalLabel: UILabel!
	
	let intervalLabelFormat = NSLocalizedString("%d Sec", comment: "Interval seconds format")
	
	@IBAction func streamingSwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "streaming")
		wifiOnlySwitch.enabled = sender.on
	}
	
	@IBAction func wifiOnlySwitchChanged(sender: UISwitch) {
		ud.setBool(sender.on, forKey: "wifiOnly")
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
			wifiOnlySwitch.enabled = false
		}
		wifiOnlySwitch.on = ud.boolForKey("wifiOnly")
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
	
	@IBAction func signInBtnPressed(sender: AnyObject) {
		let apiMgr = TessoApiManager()
		apiMgr.signIn(userId: userIdField.text!, password: passwordField.text!, onSuccess:
			{
				var alertController = UIAlertController(title: NSLocalizedString("Success", comment: "Success on AlertView"), message: NSLocalizedString("You have signed in.", comment: "You have signed in."), preferredStyle: .Alert)
				
				let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default) {
					action in
				}
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
				
				let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default) {
					action in
				}
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
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
