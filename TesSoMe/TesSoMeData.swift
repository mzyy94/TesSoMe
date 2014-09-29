//
//  TesSoMeData.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit


enum TessoMessageType: Int {
	case Unknown = -1
	case Message = 0
	case Drawing = 1
	case File = 2
};

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

	
	class func dataFromResponce(responce: NSDictionary) -> NSArray {
		let data: NSArray = responce["data"] as NSArray
		return data
	}

	class func tlFromResponce(responce: NSDictionary) -> NSArray {
		let tl: NSArray = responce["tl"] as NSArray
		return tl
	}
    
    class func convertKML(text: String) -> String {
        var kml = text.stringByReplacingOccurrencesOfString("\n", withString: "%br()", options: .RegularExpressionSearch)
        return kml
    }
	
	class func convertText(fromKML kml: String) -> String {
		var message = kml
		// space replace
		var space = " "
		for i in 2...32 {
			space += " "
			message = message.stringByReplacingOccurrencesOfString("%sp(\(i))", withString: space)
		}
		// new line replace
		message = message.stringByReplacingOccurrencesOfString("%br()", withString: "\n")
		
		// bold characters
		message = message.stringByReplacingOccurrencesOfString("%b\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch)
			
		return message
	}
	
	init(data: NSDictionary) {
		super.init()
		
		func getReplyUsernames() {
			let usernames = message.componentsSeparatedByString("@")
			for i in 1..<usernames.count {
				if usernames[i].rangeOfString("^[a-z0-9]{1,16}[^a-z0-9]?", options: .RegularExpressionSearch) != nil {
					replyUserIds.append(usernames[i].stringByReplacingOccurrencesOfString("^([a-z0-9]{1,16})[^a-z0-9]?.*", withString: "$1", options: .RegularExpressionSearch))
				}
			}
		}
		
		func getRelatedMessageIds() {
			let replies = message.componentsSeparatedByString(">")
			for i in 1..<replies.count {
				if replies[i].rangeOfString("^[0-9]{1,16}[^0-9]?", options: .RegularExpressionSearch) != nil {
					relatedMessageIds.append(replies[i].stringByReplacingOccurrencesOfString("^([0-9]{1,16})[^0-9]?.*", withString: "$1", options: .RegularExpressionSearch).toInt()!)
				}
			}
		}
		
		func getHashTags() {
			let hashtags = message.componentsSeparatedByString("#")
			for i in 1..<hashtags.count {
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
			if filedata.count > 3 {
				message = filedata[3]
			}
			fileURL = NSURL(string: "https://tesso.pw/files/snsuploads/\(filedata[0])/\(fileName!)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
		}
		getReplyUsernames()
		getRelatedMessageIds()
		getHashTags()

	}
	
	
	func generateAttributedMessage() -> NSAttributedString {
		// space replace
		var space = " "
		for i in 2...32 {
			space += " "
			message = message.stringByReplacingOccurrencesOfString("%sp(\(i))", withString: space)
		}
		// new line replace
		message = message.stringByReplacingOccurrencesOfString("%br()", withString: "\n")
		
		var attributedMessage = NSMutableAttributedString(string: message)
		
		var boldRange = NSString(string: message).rangeOfString("%b\\([^\\)]*\\)", options: .RegularExpressionSearch)
		
		while (boldRange.length > 0) {
			message = NSString(string: message).stringByReplacingOccurrencesOfString("%b\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch, range: boldRange)
			
			attributedMessage.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 250.0/255.0, green: 10.0/255.0, blue: 20.0/255.0, alpha: 1.0), range: boldRange)
			
			attributedMessage.deleteCharactersInRange(NSMakeRange(boldRange.location + boldRange.length - 1, 1))
			attributedMessage.deleteCharactersInRange(NSMakeRange(boldRange.location, 3))
			
			boldRange = NSString(string: message).rangeOfString("%b\\((.+)\\)", options: .RegularExpressionSearch)
		}
		
		for username in replyUserIds {
			var usernameRange = NSString(string: message).rangeOfString("@" + username, options: .RegularExpressionSearch)
			while (usernameRange.length > 0) {
				let userLink = NSString(format: "tesso://user/%@", username)
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: userLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: usernameRange)
				usernameRange = NSString(string: message).rangeOfString("@" + username, options: .RegularExpressionSearch, range: NSMakeRange(usernameRange.location + usernameRange.length, message.utf16Count - (usernameRange.location + usernameRange.length)))
			}
		}
		
		for messageid in relatedMessageIds {
			var relatedMsgRange = NSString(string: message).rangeOfString(">\(messageid)", options: .RegularExpressionSearch)
			while (relatedMsgRange.length > 0) {
				let messageLink = NSString(format: "tesso://message/%d", messageid)
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: messageLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: relatedMsgRange)
				relatedMsgRange = NSString(string: message).rangeOfString(">\(messageid)", options: .RegularExpressionSearch, range: NSMakeRange(relatedMsgRange.location + relatedMsgRange.length, message.utf16Count - (relatedMsgRange.location + relatedMsgRange.length)))
			}
		}

		for hashtag in hashTags {
			var hashtagRange = NSString(string: message).rangeOfString("#\(hashtag)", options: .RegularExpressionSearch)
			while (hashtagRange.length > 0) {
				let hashtagLink = NSString(format: "tesso://search/?hash=%@", hashtag)
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: hashtagLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: hashtagRange)
				hashtagRange = NSString(string: message).rangeOfString("#\(hashtag)", options: .RegularExpressionSearch, range: NSMakeRange(hashtagRange.location + hashtagRange.length, message.utf16Count - (hashtagRange.location + hashtagRange.length)))
			}
		}
		
		return attributedMessage
	}
	
	func isViaTesSoMe() -> Bool {
		return message.rangeOfString("    $", options: .RegularExpressionSearch) != nil
	}
	
	func setDataToCell(inout cell: TimelineMessageCell, withFontSize fontSize: CGFloat, withBadge: Bool) {
		cell.statusIdLabel.text = String(statusid)
		cell.usernameLabel.text = "@" + username
		cell.nicknameLabel.text = nickname
		cell.timeStampLabel.text = NSLocalizedString("0 s", comment: "Initial seconds")
		cell.userIconBtn.sd_setBackgroundImageWithURL(NSURL(string: "https://tesso.pw/img/icons/" + username + ".png"), forState: .Normal)
		cell.postedDate = date
		cell.viaTesSoMeBadge.hidden = !withBadge || !isViaTesSoMe()
		switch type {
		case .Message:
			cell.messageTextView.attributedText = generateAttributedMessage()
			cell.previewView.image = nil
		case .File:
			if fileURL!.lastPathComponent.rangeOfString("(.[jJ][pP][eE]?[gG]|.[pP][nN][gG]|.[gG][iI][fF]|.[bB][mM][pP])$", options: .RegularExpressionSearch) != nil {
				cell.previewView.sd_setImageWithURL(fileURL)
			}
			cell.messageTextView.text = fileURL?.absoluteString
		case .Drawing:
			cell.messageTextView.attributedText = generateAttributedMessage()
			let drawingURL = NSURL(string: "https://tesso.pw/img/snspics/\(statusid).png")
			cell.previewView.sd_setImageWithURL(drawingURL)
		default:
			NSLog("Unknown post type found.")
		}
		cell.messageTextView.font = UIFont.systemFontOfSize(fontSize)
		
		
	}
	
}
