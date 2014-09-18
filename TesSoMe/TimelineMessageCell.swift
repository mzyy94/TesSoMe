//
//  TimelineMessageCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TimelineMessageCell: SWTableViewCell, SWTableViewCellDelegate {
	let app = UIApplication.sharedApplication()

	@IBOutlet weak var userIconBtn: UIButton!
	@IBOutlet weak var statusIdLabel: UILabel!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var timeStampLabel: UILabel!
	@IBOutlet weak var viaTesSoMeBadge: UIImageView!
	
	
	func rightButtons() -> NSArray {
		let rightUtilityButtons = NSMutableArray()
        
		rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.lightGrayColor(), title: "More")
		rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.grayColor(), title: "Reply")
		
		return rightUtilityButtons
	}

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		// Round edge
		self.userIconBtn.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIconBtn.layer.borderWidth = 1.0
		self.userIconBtn.layer.cornerRadius = 4.0
		self.userIconBtn.clipsToBounds = true
		self.messageTextView.textContainer.lineFragmentPadding = 0
        self.messageTextView.contentInset.top = -8.0
		
		self.rightUtilityButtons = self.rightButtons()
		self.delegate = self
    }
	
	func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
		switch index {
		case 0: // More button
			app.openURL(NSURL(string: NSString(format: "tesso://message/%@", (cell as TimelineMessageCell).statusIdLabel.text!)))
		case 1: // Reply button
			let messageId = (cell as TimelineMessageCell).statusIdLabel.text!
			let username = (cell as TimelineMessageCell).usernameLabel.text!.stringByReplacingOccurrencesOfString("@", withString: "%40")
			app.openURL(NSURL(string: NSString(format: "tesso://post/?text=%@", "%3E\(messageId)(\(username))")))
		default:
			NSLog("Pressed SWTableViewCell utility button index is out of range.")
		}
		cell.hideUtilityButtonsAnimated(true)
	}
	
	func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
		return true
	}
	
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)

        // Configure the view for the selected state
    }
    
}