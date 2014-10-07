//
//  MessageDetailViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/07.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

	let apiManager = TessoApiManager()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	
	var messageFontSize: CGFloat = 0.0
	var withBadge: Bool = true
	var withImagePreview: Bool = false
	var timestampIsRelative: Bool = true

	var replyMessages: [TesSoMeData] = []
	
    var targetMessageData: TesSoMeData! = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.tableView.estimatedRowHeight = 90.5
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		self.navigationItem.title = "POST: \(targetMessageData.statusId)"

		messageFontSize = CGFloat(ud.floatForKey("fontSize"))
		withBadge = ud.boolForKey("badge")
		withImagePreview = ud.boolForKey("imagePreview")
		timestampIsRelative = ud.boolForKey("relativeTimestamp")
		self.tableView.reloadData()
		getRepliedMessage(targetMessageData.relatedMessageIds)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		self.tableView.reloadData()
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func getRepliedMessage(replies: [Int]) {
		for statusId in replies {
			apiManager.getTimeline(sinceid: statusId - 1, maxid: statusId, onSuccess:
				{ data in
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
						let timeline = TesSoMeData.tlFromResponce(data) as [NSDictionary]

						if timeline.count == 1 {
							let messageData = TesSoMeData(data:timeline[0])
							self.replyMessages.append(messageData)
							self.getRepliedMessage(messageData.relatedMessageIds)

							dispatch_sync(dispatch_get_main_queue(), {
								let path = NSIndexPath(forRow: self.replyMessages.count - 1, inSection: 2)
								self.tableView.insertRowsAtIndexPaths([path], withRowAnimation: .None)
							})
						}
					})
				}
				, onFailure: {err in println(err.localizedDescription)}
			)
			
		}
	}
	
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 0
		case 1:
			return (targetMessageData != nil).hashValue
		case 2:
			return replyMessages.count
		default:
			return 0
		}
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		switch indexPath.section {
		case 1:
			let cell = tableView.dequeueReusableCellWithIdentifier("MessageDetail", forIndexPath: indexPath) as MessageDetailViewCell
			
			if let target = targetMessageData {
				cell.userIconBtn.sd_setBackgroundImageWithURL(NSURL(string: "https://tesso.pw/img/icons/\(target.username).png"), forState: .Normal)
				cell.nicknameLabel.text = target.nickname
				cell.usernameLabel.text = "@\(target.username)"
				
				cell.statusIdLabel.text = "\(target.statusId)"
				cell.topicIdLabel.text = "\(target.topicid + 99)"
				
				let formatter = NSDateFormatter()
				formatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
				
				cell.timeStampLabel.text = formatter.stringFromDate(target.date)
				cell.viaTesSoMeBadge.hidden = target.isViaTesSoMe()
				
				if cell.viaTesSoMeBadge.hidden {
					cell.viaWhereLabel.text = "via Web?"
				} else {
					cell.viaWhereLabel.text = "via TesSoMe"
				}
				
				let messageText = NSMutableAttributedString(attributedString: target.attributedMessage)
				messageText.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: NSMakeRange(0, messageText.string.utf16Count))
				cell.messageTextView.attributedText = messageText
				
				switch target.type {
				case .Message:
					cell.previewView.image = nil
				case .File:
					if withImagePreview && target.fileSize < 1024*1024 && target.fileURL!.lastPathComponent.rangeOfString("(.jpe?g|.png|.gif|.bmp)$", options: .RegularExpressionSearch | .CaseInsensitiveSearch) != nil {
						cell.previewView.sd_setImageWithURL(target.fileURL, placeholderImage: UIImage(named: "white.png"))
					}
				case .Drawing:
					let drawingURL = NSURL(string: "https://tesso.pw/img/snspics/\(target.statusId).png")
					cell.previewView.sd_setImageWithURL(drawingURL, placeholderImage: UIImage(named: "white.png"))
				default:
					NSLog("Unknown post type found.")
				}
				cell.messageTextView.font = UIFont.systemFontOfSize(messageFontSize)

				cell.messageTextView.setNeedsDisplay()
				cell.messageTextView.setNeedsLayout()
				cell.messageTextView.setNeedsUpdateConstraints()
				
			}
			
			return cell
		default:
			var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as TimelineMessageCell
			let data = replyMessages[indexPath.row]
			data.setDataToCell(&cell, withFontSize: messageFontSize, withBadge: withBadge, withImagePreview: withImagePreview, repliedUsername: appDelegate.usernameOfTesSoMe)
			cell.updateTimestamp(relative: false)
			return cell
		}
    }
}
