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
	@IBOutlet weak var previewView: UIImageView!
	
	var postedDate: NSDate?
	
	func rightButtons() -> NSArray {
		let rightUtilityButtons = NSMutableArray()
        
		rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.lightGrayColor(), icon: UIImage(named: "comment_icon"))
		rightUtilityButtons.sw_addUtilityButtonWithColor(UIColor.grayColor(), icon: UIImage(named: "reply_icon"))
		
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
		
		self.viaTesSoMeBadge.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.viaTesSoMeBadge.layer.borderWidth = 1.0
		self.viaTesSoMeBadge.layer.cornerRadius = self.viaTesSoMeBadge.frame.height / 2
		self.viaTesSoMeBadge.clipsToBounds = true
		
		self.messageTextView.textContainer.lineFragmentPadding = 0
        self.messageTextView.contentInset.top = -8.0
		
		self.rightUtilityButtons = self.rightButtons()
		self.delegate = self
    }
	
	func updateTimestamp(#relative: Bool) {
		if relative {
			updateRelativeTimestamp()
		} else {
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "MM/dd HH:mm:ss"
			self.timeStampLabel.text = dateFormatter.stringFromDate(postedDate!)
		}
	}
	
    private func updateRelativeTimestamp() {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "s's'"
		let timeDate = NSDate(timeIntervalSinceReferenceDate: -postedDate!.timeIntervalSinceNow)
		switch timeDate.timeIntervalSinceReferenceDate {
		case 0..<60:
			dateFormatter.dateFormat = "s's'"
		case 60..<60*60:
			dateFormatter.dateFormat = "m'm 'ss's'"
		case 60*60..<60*60*12:
			dateFormatter.dateFormat = "h'h 'mm'm 'ss's'"
		default:
			dateFormatter.dateFormat = "MM/dd HH:mm:ss"
			self.timeStampLabel.text = dateFormatter.stringFromDate(postedDate!)
			return
		}
		let timeZone = NSTimeZone.systemTimeZone()
		let timeDiffSeconds = timeZone.secondsFromGMTForDate(timeDate)
		let gmtTimeDate = timeDate.dateByAddingTimeInterval(-NSTimeInterval(timeDiffSeconds))

		self.timeStampLabel.text = dateFormatter.stringFromDate(gmtTimeDate)
    }
	
	func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
		switch index {
		case 0: // More button
			app.openURL(NSURL(string: NSString(format: "tesso://message/%@", (cell as TimelineMessageCell).statusIdLabel.text!)))
		case 1: // Reply button
			let messageId = (cell as TimelineMessageCell).statusIdLabel.text!
			let username = (cell as TimelineMessageCell).usernameLabel.text!.stringByReplacingOccurrencesOfString("@", withString: "%40")
			app.openURL(NSURL(string: NSString(format: "tesso://post/?text=%@", "%3E\(messageId)(\(username))%20")))
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
