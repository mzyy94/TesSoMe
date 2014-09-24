//
//  PostMainViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/24.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class PostMainViewController: UIViewController {

	var menu: REMenu!
	
	@IBOutlet weak var postTitleBtn: UIButton!
	@IBOutlet weak var textView: UITextView!
	
	@IBAction func postTitleBtnPressed(sender: AnyObject) {
		if menu.isOpen {
			menu.close()
		} else {
			menu.showFromNavigationController(self.navigationController)
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
	}
	
	func initMenu() {
		let selectMessageItem = REMenuItem(title: NSLocalizedString("Message", comment: "Message on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("Message")
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
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	func sendPost() {
		let apiManager = TessoApiManager()
		let text = self.textView.text
		apiManager.sendMessage(topicid: 1, message: text, onSuccess: nil, onFailure: nil)
		closeView()
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
