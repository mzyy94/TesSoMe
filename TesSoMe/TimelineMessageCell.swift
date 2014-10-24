//
//  TimelineMessageCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TimelineMessageCell: SWTableViewCell, SWTableViewCellDelegate, IDMPhotoBrowserDelegate, UITextViewDelegate {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate

	@IBOutlet weak var userIconBtn: UIButton!
	@IBOutlet weak var statusIdLabel: UILabel!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var timeStampLabel: UILabel!
	@IBOutlet weak var viaTesSoMeBadge: UIImageView!
	@IBOutlet weak var previewView: UIImageView!
	@IBOutlet weak var topicIdLabel: UILabel!
	
	var postData: TesSoMeData! = nil
	
	@IBAction func userIconBtnPressed() {
		let username = usernameLabel.text?.stringByReplacingOccurrencesOfString("@", withString: "")
		
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
		userViewController.username = username!
		
		let tableView = self.superview?.superview as UITableView
		let viewController = (tableView.dataSource as AnyObject!) as UIViewController
		viewController.navigationController?.pushViewController(userViewController, animated: true)
	}
	
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
		self.messageTextView.delegate = self
		
		self.rightUtilityButtons = self.rightButtons()
		self.delegate = self
		
		self.previewView.layer.cornerRadius = 3.0
		self.previewView.clipsToBounds = true
		
		let previewViewTapGesture = UITapGestureRecognizer(target: self, action: Selector("previewViewTapped:"))
		previewViewTapGesture.numberOfTapsRequired = 1
		previewViewTapGesture.numberOfTouchesRequired = 1
		self.userInteractionEnabled = true
		self.previewView.userInteractionEnabled = true
		self.previewView.addGestureRecognizer(previewViewTapGesture)
	}
	
	func previewViewTapped(sender: UITapGestureRecognizer) {
		if sender.state == .Ended {
			let image = self.previewView.image
			let photo = IDMPhoto(image: image)
			let browser = IDMPhotoBrowser(photos: [photo], animatedFromView: self)
			browser.scaleImage = self.previewView.image
			browser.delegate = self
			browser.displayActionButton = false
			
			let tableView = self.superview?.superview as UITableView
			let viewController = (tableView.dataSource as AnyObject!) as UIViewController
			viewController.presentViewController(browser, animated: true, completion: nil)
		}
	}
	
	func updateTimestamp(#relative: Bool) {
		if relative {
			updateRelativeTimestamp()
		} else {
			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "MM/dd HH:mm:ss"
			self.timeStampLabel.text = dateFormatter.stringFromDate(postData.date)
		}
	}
	
	func photoBrowser(photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAtIndex index: UInt) -> IDMCaptionView! {
		let photo = photoBrowser.photoAtIndex(index)
		let captionView = IDMCaptionView(photo: photo)
		captionView.setupCaption()
		
		let nib = UINib(nibName: "PhotoCaptionView", bundle: nil)
		let photoCaptionView = nib.instantiateWithOwner(self, options: nil).first as PhotoCaptionView
		
		photoCaptionView.userIcon.image = self.userIconBtn.backgroundImageForState(.Normal)
		photoCaptionView.usernameLabel.text = self.usernameLabel.text
		photoCaptionView.nicknameLabel.text = self.nicknameLabel.text
		
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
		photoCaptionView.timeStampLabel.text = dateFormatter.stringFromDate(self.postData.date)
		
		photoCaptionView.viaTesSoMeBadge.hidden = self.viaTesSoMeBadge.hidden
		photoCaptionView.statusIdLabel.text = self.statusIdLabel.text
		
		photoCaptionView.messageTextView.text = self.messageTextView.text
		photoCaptionView.messageTextView.textColor = UIColor.whiteColor()
		
		photoCaptionView.setTranslatesAutoresizingMaskIntoConstraints(false)

		captionView.addSubview(photoCaptionView)
		
		let constrains: [NSLayoutAttribute: CGFloat] = [.Top: 0.0, .Left: 0.0, .Right: 0.0, .Bottom: 48.0] // Remove bottom toolbar margin
		
		for (layoutAttribute, value) in constrains {
			let constraint = NSLayoutConstraint(item: photoCaptionView, attribute: layoutAttribute, relatedBy: .Equal, toItem: captionView, attribute: layoutAttribute, multiplier: 1.0, constant: value)
			captionView.addConstraint(constraint)
		}
		
		return captionView
	}

	private func updateRelativeTimestamp() {
		let dateFormatter = NSDateFormatter()
		dateFormatter.locale = NSLocale(localeIdentifier: "en_US")
		dateFormatter.dateFormat = "s's'"
		let timeDate = NSDate(timeIntervalSinceReferenceDate: -postData.date.timeIntervalSinceNow)
		switch timeDate.timeIntervalSinceReferenceDate {
		case 0..<60:
			dateFormatter.dateFormat = "s's'"
		case 60..<60*60:
			dateFormatter.dateFormat = "m'm 'ss's'"
		case 60*60..<60*60*12:
			dateFormatter.dateFormat = "h'h 'mm'm 'ss's'"
		default:
			dateFormatter.dateFormat = "MM/dd HH:mm:ss"
			self.timeStampLabel.text = dateFormatter.stringFromDate(postData.date)
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
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			let messageDetailView = storyboard.instantiateViewControllerWithIdentifier("MessageDetailView") as MessageDetailViewController
			messageDetailView.targetMessageData = self.postData
			let tableView = self.superview?.superview as UITableView
			let viewController = (tableView.dataSource as AnyObject!) as UIViewController

			viewController.navigationController?.pushViewController(messageDetailView, animated: true)
		case 1: // Reply button
			let messageId = (cell as TimelineMessageCell).statusIdLabel.text!
			let username = (cell as TimelineMessageCell).usernameLabel.text!.stringByReplacingOccurrencesOfString("@", withString: "%40")
			let topicid = (cell as TimelineMessageCell).topicIdLabel.text!.toInt()! - 99
			app.openURL(NSURL(string: "tesso://post/?topic=\(topicid)&text=%3E\(messageId)(\(username))%20")!)
		default:
			NSLog("Pressed SWTableViewCell utility button index is out of range.")
		}
		cell.hideUtilityButtonsAnimated(true)
	}
	
	func swipeableTableViewCellShouldHideUtilityButtonsOnSwipe(cell: SWTableViewCell!) -> Bool {
		return true
	}
	
	func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
		if URL.scheme == "tesso" {
			if URL.host == "user" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
				userViewController.username = URL.lastPathComponent
				
				let tableView = self.superview?.superview as UITableView
				let viewController = (tableView.dataSource as AnyObject!) as UIViewController
				viewController.navigationController?.pushViewController(userViewController, animated: true)
				
				return false
	
			}
			
			if URL.host == "search" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let searchResultViewController = storyboard.instantiateViewControllerWithIdentifier("SearchResultView") as SearchResultViewController
				searchResultViewController.tag = URL.query?.stringByReplacingOccurrencesOfString("=", withString: "_").stringByReplacingOccurrencesOfString("&", withString: "_and_")
				
				let tableView = self.superview?.superview as UITableView
				let viewController = (tableView.dataSource as AnyObject!) as UIViewController
				viewController.navigationController?.pushViewController(searchResultViewController, animated: true)
				
				return false
				
			}

			if URL.host == "message" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let messageDetailView = storyboard.instantiateViewControllerWithIdentifier("MessageDetailView") as MessageDetailViewController
				messageDetailView.targetStatusId = URL.lastPathComponent.toInt()
				let tableView = self.superview?.superview as UITableView
				let viewController = (tableView.dataSource as AnyObject!) as UIViewController
				
				viewController.navigationController?.pushViewController(messageDetailView, animated: true)
				
				return false
				
			}
			
			return true
		}
		
		let webKitViewController = WebKitViewController()
		webKitViewController.url = URL
		
		let tableView = self.superview?.superview as UITableView
		let viewController = (tableView.dataSource as AnyObject!) as UIViewController
		viewController.navigationController?.pushViewController(webKitViewController, animated: true)
		
		return false
	}
	
	override func setSelected(selected: Bool, animated: Bool) {
		super.setSelected(false, animated: animated)

		// Configure the view for the selected state
	}
	
}
