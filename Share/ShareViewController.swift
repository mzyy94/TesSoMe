//
//  ShareViewController.swift
//  Share
//
//  Created by Yuki Mizuno on 2014/09/19.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController {
	
	let tesso_maxCharactersLimit = 1024
	
	
	override func viewDidLoad() {
		self.isContentValid()
		self.navigationController?.navigationBar.backgroundColor = UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 0.3)
		self.navigationController?.navigationBar.tintColor = UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 1.0)
		self.title = "TesSoMe"
		self.textView.tintColor = UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 1.0)
	}
	
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
		if let currentMessage = contentText {
			let currentMessageLength = countElements(currentMessage)
			self.charactersRemaining = self.tesso_maxCharactersLimit - currentMessageLength
			if Int(self.charactersRemaining) < 0 {
				return false
			}
		}
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }

    override func configurationItems() -> [AnyObject]! {
		var configurationItems: [SLComposeSheetConfigurationItem] = []
		
		if self.extensionContext?.inputItems.count == 0 {
			let attachmentConfig = SLComposeSheetConfigurationItem()
			attachmentConfig.title = NSLocalizedString("File attachment", comment: "File attachment")
			attachmentConfig.value = NSLocalizedString("None", comment: "None")
			configurationItems.append(attachmentConfig)
			
			let drawingConfig = SLComposeSheetConfigurationItem()
			drawingConfig.title = NSLocalizedString("Drawing", comment: "Drawing")
			drawingConfig.value = NSLocalizedString("None", comment: "None")
			configurationItems.append(drawingConfig)
		}
		
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return configurationItems
    }

}
