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
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	
	var messageFontSize: CGFloat = 0.0
	var withBadge: Bool = true
	var withReplyIcon: Bool = false
	var withImagePreview: Bool = false
	var timestampIsRelative: Bool = true

	var replyMessages: [TesSoMeData] = []
	
    var targetMessageData: TesSoMeData! = nil
	var targetStatusId: Int! = nil

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.tableView.estimatedRowHeight = 90.5
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		self.tableView.tableFooterView = UIView()
		
		if targetMessageData == nil {
			getTargetMessageCell()
			self.navigationItem.title = "POST: \(targetStatusId!)"
		} else {
			getRepliedMessage(targetMessageData.relatedMessageIds)
			self.navigationItem.title = "POST: \(targetMessageData.statusId)"
		}
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "reply_icon"), style: .Plain, target: self, action: Selector("replyPost"))

		messageFontSize = CGFloat(ud.floatForKey("fontSize"))
		withBadge = ud.boolForKey("badge")
		withReplyIcon = ud.boolForKey("replyIcon")
		withImagePreview = ud.boolForKey("imagePreview")
		timestampIsRelative = ud.boolForKey("relativeTimestamp")
		self.tableView.reloadData()
	}
	
	func replyPost() {
		app.openURL(NSURL(string: "tesso://post/?topic=\(targetMessageData.topicid)&text=%3E\(targetMessageData.statusId)(%40\(targetMessageData.username))%20"))
	}
	
	func getTargetMessageCell() {
		apiManager.getTimeline(sinceid: targetStatusId - 1, maxid: targetStatusId, onSuccess:
			{ data in
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					let timeline = TesSoMeData.tlFromResponce(data) as [NSDictionary]
					func cantGetMessage() {
						dispatch_sync(dispatch_get_main_queue(), {
							let notification = MPGNotification(title: NSLocalizedString("Can not get the message", comment: "Can not get the message"), subtitle: NSLocalizedString("No message found", comment: "No message found"), backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
							notification.duration = 5.0
							notification.animationType = .Drop
							notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
							notification.swipeToDismissEnabled = false
							notification.show()
						})
						self.navigationController?.popViewControllerAnimated(true)
					}
					if timeline.count == 1 {
						let tessomeData = TesSoMeData(data:timeline[0])
						if tessomeData.statusId == self.targetStatusId {
							dispatch_sync(dispatch_get_main_queue(), {
								self.targetMessageData = tessomeData
								self.tableView.reloadData()
								self.getRepliedMessage(self.targetMessageData.relatedMessageIds)
							})
						} else {
							cantGetMessage()
						}
					} else {
						cantGetMessage()
					}

				})
			}
			, onFailure: {err in println(err.localizedDescription)}
		)
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
			if replyMessages.filter({mes in mes.statusId == statusId}).count != 0 {
				return
			}
			apiManager.getTimeline(sinceid: statusId - 1, maxid: statusId, onSuccess:
				{ data in
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
						let timeline = TesSoMeData.tlFromResponce(data) as [NSDictionary]

						if timeline.count == 1 {
							let messageData = TesSoMeData(data:timeline[0])
							self.replyMessages.append(messageData)
							self.getRepliedMessage(messageData.relatedMessageIds)

							dispatch_sync(dispatch_get_main_queue(), {
								self.tableView.reloadData()
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
			return 1
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
				cell.viaTesSoMeBadge.hidden = !target.isViaTesSoMe()
				
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
			data.setDataToCell(&cell, withFontSize: messageFontSize, withBadge: withBadge, withImagePreview: withImagePreview, repliedUsername: appDelegate.usernameOfTesSoMe, withReplyIcon: withReplyIcon)
			cell.updateTimestamp(relative: false)
			return cell
		}
    }
}
