//
//  TesSoMeURLSchemeManager.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/12/28.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TesSoMeURLSchemeManager: NSURL {
	enum route {
		case post, reply, message, user, search, hashtag
	}
	
	class func routing(URL: NSURL, viewController: UIViewController) -> Bool{
		if URL.scheme == "tesso" {
			if URL.host == "user" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
				userViewController.username = URL.lastPathComponent!
				

				viewController.navigationController?.pushViewController(userViewController, animated: true)
				
				return false
				
			}
			
			if URL.host == "message" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let messageDetailView = storyboard.instantiateViewControllerWithIdentifier("MessageDetailView") as MessageDetailViewController
				messageDetailView.targetStatusId = URL.lastPathComponent?.toInt()
				
				viewController.navigationController?.pushViewController(messageDetailView, animated: true)
				
				return false
				
			}
			
			if URL.host == "search" {
				let storyboard = UIStoryboard(name: "Main", bundle: nil)
				let searchResultViewController = storyboard.instantiateViewControllerWithIdentifier("SearchResultView") as SearchResultViewController
				searchResultViewController.tag = URL.query?.stringByReplacingOccurrencesOfString("=", withString: "_").stringByReplacingOccurrencesOfString("&", withString: "_and_")
				

				viewController.navigationController?.pushViewController(searchResultViewController, animated: true)
				
				return false
				
			}
			
			return true
		}
		
		let webKitViewController = WebKitViewController()
		webKitViewController.url = URL
		
		viewController.navigationController?.pushViewController(webKitViewController, animated: true)
		
		return false
	}
	
	class func openURL(type: route, topicid: Int! = nil, text: String! = nil, username: String! = nil, statusid: Int! = nil, hashtag: String! = nil) {
		
		let url = self.getURL(type, topicid: topicid, text: text, username: username, statusid: statusid, hashtag: hashtag)
		UIApplication.sharedApplication().openURL(url)
	}
	
	class func getURL(type: route, topicid: Int! = nil, text: String! = nil, username: String! = nil, statusid: Int! = nil, hashtag: String! = nil) -> NSURL {
		var urlString = "tesso://"
		
		switch type {
		case .post:
			urlString += "post/"
			urlString += "?topic=\(topicid)&text=\(text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"
		case .reply:
			urlString += "post/"
			urlString += "?topic=\(topicid)&text=%3E\(statusid)(%40\(username))%20"
		case .message:
			urlString += "message/"
			urlString += "\(statusid)"
		case .user:
			urlString += "user/"
			urlString += "\(username)"
		case .search:
			urlString += "search/"
		case .hashtag:
			urlString += "search/"
			urlString += "?=\(hashtag)"
		}
		
		return NSURL(string: urlString)!
	}
}
