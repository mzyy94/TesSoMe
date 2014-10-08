//
//  IntroSignIn.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/08.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class IntroSignIn: UIView, UITextFieldDelegate {
	let apiManager = TessoApiManager()
	
	@IBOutlet weak var usernameField: UITextField!
	@IBOutlet weak var passwordField: UITextField!
	@IBOutlet weak var signInBtn: UIButton!
	
	@IBAction func signInBtnPressed() {
		signIn()
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
	
		self.signInBtn.layer.borderColor = UIColor.whiteColor().CGColor
		self.signInBtn.layer.borderWidth = 1.0
		self.signInBtn.layer.cornerRadius = 4.0
		self.signInBtn.clipsToBounds = true
		
		changePlaceholderTextColor(self.usernameField)
		changePlaceholderTextColor(self.passwordField)
		
		self.usernameField.delegate = self
		self.passwordField.delegate = self
	}
	
	func signIn() {
		let username = usernameField.text
		let password = passwordField.text
		
		apiManager.signIn(username: username, password: password, onSuccess:
			{
				let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
				
				
				appDelegate.usernameOfTesSoMe = username
				appDelegate.passwordOfTesSoMe = password
				
				let serviceName = "TesSoMe"
				SSKeychain.setPassword(password, forService: serviceName, account: username)
				
				let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("goNextPage"), userInfo: nil, repeats: false)
			}
			, onFailure:
			{ err in
				var alertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error on AlertView"), message: err.localizedDescription, preferredStyle: .Alert)
				
				let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler: nil)
				alertController.addAction(okAction)
				
				self.window?.rootViewController?.presentViewController(alertController, animated: true, completion: nil)
			}
		)
		
		usernameField.resignFirstResponder()
		passwordField.resignFirstResponder()
	}
	
	func goNextPage() {
		let introView = self.superview?.superview?.superview as EAIntroView
		introView.setCurrentPageIndex(introView.currentPageIndex + 1, animated: true)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		
		drawUnderline(self.usernameField.frame)
		drawUnderline(self.passwordField.frame)
	}
	
	func changePlaceholderTextColor(textField: UITextField) {
		let placeholderText = textField.placeholder
		textField.attributedPlaceholder = NSAttributedString(string: placeholderText!, attributes: [NSForegroundColorAttributeName: UIColor(white: 0.9, alpha: 1.0)])
	}
	
	func textFieldShouldReturn(textField: UITextField!) -> Bool {
		if (textField == usernameField) {
			passwordField.becomeFirstResponder()
		} else if (textField == passwordField) {
			passwordField.resignFirstResponder()
			signIn()
		}
		
		return true
	}
	
	func drawUnderline(frame: CGRect) {
		let line = CAShapeLayer()
		let path = UIBezierPath()
		
		let start = CGPoint(x: frame.origin.x, y: frame.origin.y + frame.height)
		let end = CGPoint(x: start.x + frame.width, y: start.y)

		path.moveToPoint(start)
		path.addLineToPoint(end)
		
		line.path = path.CGPath
		
		line.strokeColor = UIColor.whiteColor().CGColor
		line.fillColor = nil
		line.lineWidth = 1.0
		
		self.layer.addSublayer(line)
	}
	
}
