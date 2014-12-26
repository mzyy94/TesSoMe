//
//  MessageDetailViewCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/07.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class MessageDetailViewCell: UITableViewCell, UITextViewDelegate {

	
	@IBOutlet weak var userIconBtn: UIButton!
	@IBOutlet weak var viaTesSoMeBadge: UIImageView!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var previewView: UIImageView!
	@IBOutlet weak var statusIdLabel: UILabel!
	@IBOutlet weak var topicIdLabel: UILabel!
	@IBOutlet weak var viaWhereLabel: UILabel!
	@IBOutlet weak var timeStampLabel: UILabel!
	
	var targetMessageCell: TimelineMessageCell! = nil
	
	override func awakeFromNib() {
        super.awakeFromNib()
		
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
		
		self.statusIdLabel.superview!.layer.borderColor = UIColor(white: 1.0, alpha: 0.9).CGColor
		self.statusIdLabel.superview!.layer.borderWidth = 1.0
		
		self.topicIdLabel.superview!.layer.borderColor = UIColor(white: 1.0, alpha: 0.9).CGColor
		self.topicIdLabel.superview!.layer.borderWidth = 1.0
		
		self.timeStampLabel.superview!.layer.borderColor = UIColor(white: 1.0, alpha: 0.9).CGColor
		self.timeStampLabel.superview!.layer.borderWidth = 1.0
		
		self.viaWhereLabel.superview!.layer.borderColor = UIColor(white: 1.0, alpha: 0.9).CGColor
		self.viaWhereLabel.superview!.layer.borderWidth = 1.0
		
		
		
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
			browser.displayActionButton = false
			
			let tableView = self.superview?.superview as UITableView
			let viewController = (tableView.dataSource as AnyObject!) as UIViewController
			viewController.presentViewController(browser, animated: true, completion: nil)
		}
	}
	
	func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
		if URL.scheme == "tesso" {
			if URL.host == "user" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
				userViewController.username = URL.lastPathComponent!
				
				let tableView = self.superview?.superview as UITableView
				let viewController = (tableView.dataSource as AnyObject!) as UIViewController
				viewController.navigationController?.pushViewController(userViewController, animated: true)
				
				return false
				
			}
			
			if URL.host == "message" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let messageDetailView = storyboard.instantiateViewControllerWithIdentifier("MessageDetailView") as MessageDetailViewController
				messageDetailView.targetStatusId = URL.lastPathComponent?.toInt()

				let tableView = self.superview?.superview as UITableView
				let viewController = (tableView.dataSource as AnyObject!) as UIViewController
				viewController.navigationController?.pushViewController(messageDetailView, animated: true)
				
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
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
