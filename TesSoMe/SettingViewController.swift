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
	
    override func viewDidLoad() {
        super.viewDidLoad()

        self.userIdField.text = appDelegate.usernameOfTesSoMe
        self.passwordField.text = appDelegate.passwordOfTesSoMe
		
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
