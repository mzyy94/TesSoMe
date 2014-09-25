//
//  PostMainViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/24.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class PostMainViewController: UIViewController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()

	var menu: REMenu!
	
	@IBOutlet weak var postTitleBtn: UIButton!
	@IBOutlet weak var textView: UITextView!
	
	@IBAction func postTitleBtnPressed(sender: AnyObject) {
		if menu.isOpen {
			menu.closeWithCompletion({
				self.showKeyboard()
			})
		} else {
			menu.showFromNavigationController(self.navigationController)
            closeKeyboard()
		}
	}
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		initMenu()
		
		setTitleBtnText("Message")
		
		self.providesPresentationContextTransitionStyle = true
		self.definesPresentationContext = true
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("closeView"))

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("sendPost"))
		
		showKeyboard()
	}
	
	func initMenu() {
		let selectMessageItem = REMenuItem(title: NSLocalizedString("Message", comment: "Message on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("Message")
			self.showKeyboard()
		})
		let selectFileUploadItem = REMenuItem(title: NSLocalizedString("File upload", comment: "File upload on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("File upload")
		})
		let selectDrawingItem = REMenuItem(title: NSLocalizedString("Drawing", comment: "Drawing on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("Drawing")
		})
		self.menu = REMenu(items: [selectMessageItem, selectFileUploadItem, selectDrawingItem])
		menu.liveBlur = true
		menu.liveBlurBackgroundStyle = REMenuLiveBackgroundStyle.Dark
		menu.separatorColor = UIColor(white: 0.0, alpha: 0.4)
		menu.borderColor = UIColor.clearColor()
		menu.textColor = UIColor(white: 1.0, alpha: 0.78)
	}
	
	func setTitleBtnText(text: String) {
		self.postTitleBtn.backgroundColor = UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 1.0)
		self.postTitleBtn.layer.cornerRadius = 14.0
		self.postTitleBtn.clipsToBounds = true
		let titleText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0), NSForegroundColorAttributeName: UIColor.whiteColor()])
		let dropDownMenuText = NSAttributedString(string: "  ▼", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(10.0), NSForegroundColorAttributeName: UIColor.whiteColor()])
		
		titleText.appendAttributedString(dropDownMenuText)
		self.postTitleBtn.setAttributedTitle(titleText, forState: .Normal)
	}
	
	func closeView() {
		closeKeyboard()
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	func closeView(completion: (() -> Void)! = nil) {
		closeKeyboard()
		self.dismissViewControllerAnimated(true, completion: completion)
	}
    
    func showKeyboard() {
        self.textView.becomeFirstResponder()
    }
    
    func closeKeyboard() {
        self.textView.endEditing(true)
    }

	func sendPost() {
		let apiManager = TessoApiManager()
		let text = self.textView.text
		closeView({
			apiManager.sendMessage(topicid: 1, message: text, onSuccess: nil, onFailure: {
				err in
				let notification = MPGNotification(title: NSLocalizedString("Post failed.", comment: "Post failed."), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
				notification.duration = 5.0
				notification.animationType = .Drop
				notification.setButtonConfiguration(.OneButton, withButtonTitles: [NSLocalizedString("Edit", comment: "Edit")])
				notification.buttonHandler = {
					notification, buttonIndex in
					if buttonIndex == notification.firstButton.tag ||
						buttonIndex == notification.backgroundView.tag {
							self.app.openURL(NSURL(string: NSString(format: "tesso://post/?text=%@", text)))
					}
				}
				notification.show()
			})
		})
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
