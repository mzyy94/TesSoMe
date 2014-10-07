//
//  MessageDetailViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/07.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class MessageDetailViewController: UITableViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.tableView.estimatedRowHeight = 200.0
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		self.navigationItem.title = "POST: \(targetMessageCell.statusIdLabel.text!)"
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
	
	var targetMessageCell: TimelineMessageCell! = nil

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case 0:
			return 0
		case 1:
			return (targetMessageCell != nil).hashValue
		case 2:
			return 0
		default:
			return 0
		}
    }

	
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("MessageDetail", forIndexPath: indexPath) as MessageDetailViewCell
		
		if let target = targetMessageCell {
			cell.userIconBtn.setBackgroundImage(target.userIconBtn.backgroundImageForState(.Normal), forState: .Normal)
			cell.nicknameLabel.text = target.nicknameLabel.text
			cell.usernameLabel.text = target.usernameLabel.text
			
			cell.statusIdLabel.text = target.statusIdLabel.text
			cell.topicIdLabel.text = target.topicIdLabel.text
			
			let formatter = NSDateFormatter()
			formatter.dateFormat = "YYYY/MM/dd HH:mm:ss"
			
			cell.timeStampLabel.text = formatter.stringFromDate(target.postedDate!)
			cell.viaTesSoMeBadge.hidden = target.viaTesSoMeBadge.hidden
			
			if cell.viaTesSoMeBadge.hidden {
				cell.viaWhereLabel.text = "via Web?"
			} else {
				cell.viaWhereLabel.text = "via TesSoMe"
			}
			
			let messageText = NSMutableAttributedString(attributedString: target.messageTextView.attributedText)
			messageText.addAttribute(NSForegroundColorAttributeName, value: UIColor.whiteColor(), range: NSMakeRange(0, messageText.string.utf16Count))
			cell.messageTextView.attributedText = messageText
			
			cell.previewView.image = target.previewView.image
			
			cell.messageTextView.font = target.messageTextView.font
			cell.messageTextView.setNeedsDisplay()
			cell.messageTextView.setNeedsLayout()
			cell.messageTextView.setNeedsUpdateConstraints()
			
		}
		
        // Configure the cell...

        return cell
    }
}
