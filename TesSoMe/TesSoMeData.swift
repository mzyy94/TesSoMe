//
//  TesSoMeData.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TesSoMeData: NSObject {
	
	var statusid = -1
	var nickname = ""
	var username = ""
	var date = NSDate()
	var topicid = 0
	var type = TessoMessageType.Unknown
	var message = ""
	var relatedMessageIds: [Int] = []
	var replyUserIds: [String] = []
	var hashTags: [String] = []
	var fileURL: NSURL?
	var fileSize: Int?
	var fileName: String?
	
	
	enum TessoMessageType: Int {
		case Unknown = -1
		case Message = 0
		case Drawing = 1
		case File = 2
	};

	
	class func dataFromResponce(#responce: NSDictionary) -> NSArray {
		let data: NSArray = responce["data"] as NSArray
		return data
	}

	class func tlFromResponce(responce: NSDictionary) -> NSArray {
		let tl: NSArray = responce["tl"] as NSArray
		return tl
	}
	
	init(data: NSDictionary) {
		super.init()
		
		func getReplyUsernames() {
			let usernames = message.componentsSeparatedByString("@")
			for var i = 1; i < usernames.count; i++ {
				if usernames[i].rangeOfString("^[a-z0-9]{1,16}[^a-z0-9]?", options: .RegularExpressionSearch) != nil {
					replyUserIds.append(usernames[i].stringByReplacingOccurrencesOfString("^([a-z0-9]{1,16})[^a-z0-9]?.*", withString: "$1", options: .RegularExpressionSearch))
				}
			}
		}
		
		func getRelatedMessageIds() {
			let replies = message.componentsSeparatedByString(">")
			for var i = 1; i < replies.count; i++ {
				if replies[i].rangeOfString("^[0-9]{1,16}[^0-9]?", options: .RegularExpressionSearch) != nil {
					relatedMessageIds.append(replies[i].stringByReplacingOccurrencesOfString("^([0-9]{1,16})[^0-9]?.*", withString: "$1", options: .RegularExpressionSearch).toInt()!)
				}
			}
		}
		
		func getHashTags() {
			let hashtags = message.componentsSeparatedByString("#")
			for var i = 1; i < hashtags.count; i++ {
				if hashtags[i].rangeOfString("^[a-zA-Z0-9]{1,16}[^a-zA-Z0-9]?", options: .RegularExpressionSearch) != nil {
					hashTags.append(hashtags[i].stringByReplacingOccurrencesOfString("^([a-zA-Z0-9]{1,16})[^a-zA-Z0-9]?.*", withString: "$1", options: .RegularExpressionSearch))
				}
			}
		}
		
		statusid = (data["statusid"] as String).toInt()!
		nickname = data["nickname"] as String
		username = data["username"] as String
		let unixtime = (data["unixtime"] as String).toInt()!
		date = NSDate(timeIntervalSince1970: Double(unixtime))
		topicid = (data["topicid"] as String).toInt()!
		type = TessoMessageType.fromRaw((data["type"] as String).toInt()!)!
		
		let converter = HTMLEntityConverter()
		
		switch type {
		case .Message, .Drawing:
			message = converter.decodeXML(data["data"] as String)
		default:
			let filedata = converter.decodeXML(data["data"] as String).componentsSeparatedByString(",")
			fileName = filedata[1]
			fileSize = filedata[2].toInt()
			message = filedata[3]
			fileURL = NSURL(string: "https://tesso.pw/files/snsuploads/\(filedata[0])/\(fileName!)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
		}
		getReplyUsernames()
		getRelatedMessageIds()
		getHashTags()

	}
	
	
	func generateAttributedMessage() -> NSAttributedString {
		// space replace
		var space = " "
		for var i = 2; i < 32; i++ {
			space += " "
			message = message.stringByReplacingOccurrencesOfString("%sp(\(i))", withString: space)
		}
		// new line replace
		let newLine = "\n"
		message = message.stringByReplacingOccurrencesOfString("%br()", withString: newLine)
		
		var attributedMessage = NSMutableAttributedString(string: message)
		
		var boldRange = NSString(string: message).rangeOfString("%b\\([^\\)]*\\)", options: .RegularExpressionSearch)
		
		while (boldRange.length > 0) {
			message = NSString(string: message).stringByReplacingOccurrencesOfString("%b\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch, range: boldRange)
			
			attributedMessage.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 250.0/255.0, green: 10.0/255.0, blue: 20.0/255.0, alpha: 1.0), range: boldRange)
			
			attributedMessage.deleteCharactersInRange(NSMakeRange(boldRange.location + boldRange.length - 1, 1))
			attributedMessage.deleteCharactersInRange(NSMakeRange(boldRange.location, 3))
			
			boldRange = NSString(string: message).rangeOfString("%b\\((.+)\\)", options: .RegularExpressionSearch)
		}
		
		for var i = 0; i < replyUserIds.count; i++ {
			var usernameRange = NSString(string: message).rangeOfString("@" + replyUserIds[i], options: .RegularExpressionSearch)
			while (usernameRange.length > 0) {
				let userLink = NSString(format: "tesso://user/%@", replyUserIds[i])
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: userLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: usernameRange)
				usernameRange = NSString(string: message).rangeOfString("@" + replyUserIds[i], options: .RegularExpressionSearch, range: NSMakeRange(usernameRange.location + usernameRange.length, message.utf16Count - (usernameRange.location + usernameRange.length)))
			}
		}
		
		for var i = 0; i < relatedMessageIds.count; i++ {
			var relatedMsgRange = NSString(string: message).rangeOfString(">\(relatedMessageIds[i])", options: .RegularExpressionSearch)
			while (relatedMsgRange.length > 0) {
				let messageLink = NSString(format: "tesso://message/%d", relatedMessageIds[i])
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: messageLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: relatedMsgRange)
				relatedMsgRange = NSString(string: message).rangeOfString(">\(relatedMessageIds[i])", options: .RegularExpressionSearch, range: NSMakeRange(relatedMsgRange.location + relatedMsgRange.length, message.utf16Count - (relatedMsgRange.location + relatedMsgRange.length)))
			}
		}

		for var i = 0; i < hashTags.count; i++ {
			var hashtagRange = NSString(string: message).rangeOfString("#\(hashTags[i])", options: .RegularExpressionSearch)
			while (hashtagRange.length > 0) {
				let messageLink = NSString(format: "tesso://search/?hash=%s", hashTags[i])
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: messageLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: hashtagRange)
				hashtagRange = NSString(string: message).rangeOfString("#\(hashTags[i])", options: .RegularExpressionSearch, range: NSMakeRange(hashtagRange.location + hashtagRange.length, message.utf16Count - (hashtagRange.location + hashtagRange.length)))
			}
		}
		
		return attributedMessage
	}
	
	func isViaTesSoMe() -> Bool {
		if message.rangeOfString("    $", options: NSStringCompareOptions.RegularExpressionSearch) != nil {
			return true
		}
		return false
	}
	
	func setDataToCell(inout cell: TimelineMessageCell) {
		cell.statusIdLabel.text = String(statusid)
		cell.usernameLabel.text = "@" + username
		cell.nicknameLabel.text = nickname
		cell.timeStampLabel.text = NSLocalizedString("0 s", comment: "Initial seconds")
		cell.messageTextView.attributedText = generateAttributedMessage()
		cell.userIconBtn.setImage(UIImage(data: NSData(contentsOfURL: NSURL(string: "https://tesso.pw/img/icons/" + username + ".png")), scale: 0.5), forState: .Normal)
	}
	
}
