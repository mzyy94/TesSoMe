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
	
	var statusId: Int = -1
	var nickname: String = ""
	var username: String = ""
	var date: NSDate = NSDate()
	var topicid: Int = 0
	var type: TessoMessageType = .Unknown
	var message: String = ""
	var relatedMessageIds: [Int] = []
	var replyUserIds: [String] = []
	var hashTags: [String] = []
	var fileURL: NSURL? = nil
	var fileSize: Int? = nil
	var fileName: String? = nil
    var attributedMessage: NSAttributedString! = nil

	
	class func dataFromResponce(responce: NSDictionary) -> NSArray {
		let data = responce["data"] as NSArray
		return data
	}

	class func tlFromResponce(responce: NSDictionary) -> NSArray {
		let tl = responce["tl"] as NSArray
		return tl
	}
	
	class func convertKML(text: String) -> String {
		let kml = text.stringByReplacingOccurrencesOfString("\n", withString: "%br()", options: .RegularExpressionSearch)
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
				let range =  usernames[i].rangeOfString("^[a-z0-9]{1,16}(?![a-z0-9])", options: .RegularExpressionSearch)
				if range != nil {
					replyUserIds.append(usernames[i].substringWithRange(range!))
				}
			}
		}
		
		func getRelatedMessageIds() {
			let replies = message.componentsSeparatedByString(">")
			for i in 1..<replies.count {
				let range = replies[i].rangeOfString("^[0-9]{1,16}(?![0-9])", options: .RegularExpressionSearch)
				if range != nil {
					relatedMessageIds.append(replies[i].substringWithRange(range!).toInt()!)
				}
			}
		}
		
		func getHashTags() {
			let hashtags = message.componentsSeparatedByString("#")
			for i in 1..<hashtags.count {
				let range = hashtags[i].rangeOfString("^[a-zA-Z0-9]{1,16}(?![a-zA-Z0-9])", options: .RegularExpressionSearch)
				if range != nil {
					hashTags.append(hashtags[i].substringWithRange(range!))
				}
			}
		}
		
		statusId = (data["statusid"] as String).toInt()!
		nickname = data["nickname"] as String
		username = data["username"] as String
		let unixtime = (data["unixtime"] as String).toInt()!
		date = NSDate(timeIntervalSince1970: NSTimeInterval(unixtime))
		topicid = (data["topicid"] as String).toInt()!
		type = TessoMessageType.fromRaw((data["type"] as String).toInt()!)!
		
		let converter = HTMLEntityConverter()
		
		switch type {
		case .Message, .Drawing:
			message = converter.decodeXML(data["data"] as String)
			getReplyUsernames()
			getRelatedMessageIds()
			getHashTags()
            attributedMessage = generateAttributedMessage()
		default:
			let filedata = converter.decodeXML(data["data"] as String).componentsSeparatedByString(",")
			fileName = filedata[1]
			fileSize = filedata[2].toInt()
			if filedata.count > 3 {
				message = filedata[3]
			}
			fileURL = NSURL(string: "https://tesso.pw/files/snsuploads/\(filedata[0])/\(fileName!)".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)
            
            var filesizeText = ""
            switch fileSize! {
            case 0..<4096:
                filesizeText = "\(fileSize!) Byte"
            case 4096..<4096*1024:
                filesizeText = "\(fileSize! / 1024) KB"
            case 4096*1024..<4096*1024*1024:
                filesizeText = "\(fileSize! / 1024 / 1024) MB"
            default:
                filesizeText = "\(fileSize! / 1024 / 1024 / 1024) GB"
            }
            
            let attributedText = NSMutableAttributedString(string: fileName!, attributes: [NSLinkAttributeName: fileURL!])
            attributedText.appendAttributedString(NSAttributedString(string: " [\(filesizeText)]"))
            attributedMessage = attributedText
            message = attributedText.string
		}
	}
	
	class func convertAttributedProfile(raw: String) -> NSMutableAttributedString {
		let converter = HTMLEntityConverter()
		var data = converter.decodeXML(raw)
		
		var space = " "
		for i in 2...32 {
			space += " "
			data = data.stringByReplacingOccurrencesOfString("%sp(\(i))", withString: space)
		}
		data = data.stringByReplacingOccurrencesOfString("%br()", withString: "\n")
		data = data.stringByReplacingOccurrencesOfString("(%h3\\([^\\)]*\\))", withString: "\n$1\n", options: .RegularExpressionSearch)
		data = data.stringByReplacingOccurrencesOfString("(%h2\\([^\\)]*\\))", withString: "\n$1\n", options: .RegularExpressionSearch)
		data = data.stringByReplacingOccurrencesOfString("%p\\(([^\\)]*)\\)", withString: "$1\n", options: .RegularExpressionSearch)
		
		let size: CGFloat = 12.0
		var text = NSMutableAttributedString(string: data, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(size)])
		
		var boldRange = NSString(string: data).rangeOfString("%b\\([^\\)]*\\)", options: .RegularExpressionSearch)
		while boldRange.length != 0 {
			data = NSString(string: data).stringByReplacingOccurrencesOfString("%b\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch, range: boldRange)
			
			text.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 250.0 / 255.0, green: 10.0/255.0, blue: 20.0/255.0, alpha: 1.0), range: boldRange)
			
			text.deleteCharactersInRange(NSMakeRange(boldRange.location + boldRange.length - 1, 1))
			text.deleteCharactersInRange(NSMakeRange(boldRange.location, 3))
			boldRange = NSString(string: data).rangeOfString("%b\\([^\\)]*\\)", options: .RegularExpressionSearch, range: NSMakeRange(boldRange.location + boldRange.length - 4, data.utf16Count - (boldRange.location + boldRange.length - 4)))
		}
		
		var h3Range = NSString(string: data).rangeOfString("%h3\\([^\\)]*\\)", options: NSStringCompareOptions.RegularExpressionSearch)
		while h3Range.length != 0 {
			data = NSString(string: data).stringByReplacingOccurrencesOfString("%h3\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch, range: h3Range)
			text.addAttribute(NSForegroundColorAttributeName, value: UIColor(red: 250.0 / 255.0, green: 120.0/255.0, blue: 20.0/255.0, alpha: 1.0), range: h3Range)
			text.deleteCharactersInRange(NSMakeRange(h3Range.location + h3Range.length - 1, 1))
			text.deleteCharactersInRange(NSMakeRange(h3Range.location, 4))
			
			h3Range = NSString(string: data).rangeOfString("%h3\\([^\\)]*\\)", options: .RegularExpressionSearch, range: NSMakeRange(h3Range.location + h3Range.length - 5, data.utf16Count - (h3Range.location + h3Range.length - 5)))
		}
		
		var h2Range = NSString(string: data).rangeOfString("%h2\\([^\\)]*\\)", options: .RegularExpressionSearch)
		while h2Range.length != 0 {
			let font = UIFont.boldSystemFontOfSize(size)
			
			data = NSString(string: data).stringByReplacingOccurrencesOfString("%h2\\(([^\\)]*)\\)", withString: "$1", options: .RegularExpressionSearch, range: h2Range)
			text.addAttribute(NSFontAttributeName, value: font, range: h2Range)
			
			text.deleteCharactersInRange(NSMakeRange(h2Range.location + h2Range.length - 1, 1))
			text.deleteCharactersInRange(NSMakeRange(h2Range.location, 4))
			
			h2Range = NSString(string: data).rangeOfString("%h2\\([^\\)]*\\)", options: .RegularExpressionSearch, range: NSMakeRange(h2Range.location + h2Range.length - 5, data.utf16Count - (h2Range.location + h2Range.length - 5)))
		}
		
		return text
	}
	
	
	private func generateAttributedMessage() -> NSAttributedString {
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
				let userLink = "tesso://user/\(username)"
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: userLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: usernameRange)
				usernameRange = NSString(string: message).rangeOfString("@" + username, options: .RegularExpressionSearch, range: NSMakeRange(usernameRange.location + usernameRange.length, message.utf16Count - (usernameRange.location + usernameRange.length)))
			}
		}
		
		for messageId in relatedMessageIds {
			var relatedMsgRange = NSString(string: message).rangeOfString(">\(messageId)", options: .RegularExpressionSearch)
			while (relatedMsgRange.length > 0) {
				let messageLink = "tesso://message/\(messageId)"
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: messageLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: relatedMsgRange)
				relatedMsgRange = NSString(string: message).rangeOfString(">\(messageId)", options: .RegularExpressionSearch, range: NSMakeRange(relatedMsgRange.location + relatedMsgRange.length, message.utf16Count - (relatedMsgRange.location + relatedMsgRange.length)))
			}
		}

		for hashtag in hashTags {
			var hashtagRange = NSString(string: message).rangeOfString("#\(hashtag)", options: .RegularExpressionSearch)
			while (hashtagRange.length > 0) {
				let hashtagLink = "tesso://search/?hash=\(hashtag)"
				attributedMessage.addAttributes([NSLinkAttributeName: NSURL(string: hashtagLink), NSForegroundColorAttributeName: UIColor(red: 120.0 / 255.0, green: 120.0/255.0, blue: 253.0/255.0, alpha: 1.0)], range: hashtagRange)
				hashtagRange = NSString(string: message).rangeOfString("#\(hashtag)", options: .RegularExpressionSearch, range: NSMakeRange(hashtagRange.location + hashtagRange.length, message.utf16Count - (hashtagRange.location + hashtagRange.length)))
			}
		}
		
		return attributedMessage
	}
	
	func isViaTesSoMe() -> Bool {
		return message.rangeOfString("    $", options: .RegularExpressionSearch) != nil
	}
    
    func isReplyTo(username: String) -> Bool {
        return Bool(replyUserIds.filter({u in u == username}).count)
    }
	
	func setDataToCell(inout cell: TimelineMessageCell, withFontSize fontSize: CGFloat, withBadge: Bool, repliedUsername: String! = nil) {
		cell.statusIdLabel.text = "\(statusId)"
		cell.usernameLabel.text = "@\(username)"
		cell.nicknameLabel.text = nickname
		cell.timeStampLabel.text = NSLocalizedString("0 s", comment: "Initial seconds")
		cell.userIconBtn.sd_setBackgroundImageWithURL(NSURL(string: "https://tesso.pw/img/icons/\(username).png"), forState: .Normal)
		cell.postedDate = date
		cell.viaTesSoMeBadge.hidden = !withBadge || !isViaTesSoMe()
		if repliedUsername != nil && isReplyTo(repliedUsername) {
			cell.backgroundColor = UIColor.globalTintColor(alpha: 0.1)
		} else {
			cell.backgroundColor = UIColor.whiteColor()
		}
        cell.messageTextView.attributedText = attributedMessage
		switch type {
		case .Message:
			cell.previewView.image = nil
		case .File:
			if fileURL!.lastPathComponent.rangeOfString("(.jpe?g|.png|.gif|.bmp)$", options: .RegularExpressionSearch | .CaseInsensitiveSearch) != nil {
				cell.previewView.sd_setImageWithURL(fileURL, placeholderImage: UIImage(named: "white.png"))
			}
		case .Drawing:
			let drawingURL = NSURL(string: "https://tesso.pw/img/snspics/\(statusId).png")
			cell.previewView.sd_setImageWithURL(drawingURL, placeholderImage: UIImage(named: "white.png"))
		default:
			NSLog("Unknown post type found.")
		}
		cell.messageTextView.font = UIFont.systemFontOfSize(fontSize)
		
		
	}
	
}
