//
//  ShareViewController.swift
//  Share
//
//  Created by Yuki Mizuno on 2014/09/19.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import Social

class ShareViewController: SLComposeServiceViewController, UITableViewDelegate, UITableViewDataSource {
	
	let tesso_maxCharactersLimit = 1024
	let tesso_maxFilenameLimit = 64
	let apiManager = TessoApiManager()

	var topicId = 1
	var topics: [NSDictionary] = []
	
	var isFileShare = true

	let selectTopicViewController = UITableViewController()
	let topicConfig = SLComposeSheetConfigurationItem()
	
	override func viewDidLoad() {
		self.navigationController?.navigationBar.backgroundColor = UIColor.globalTintColor(alpha: 0.3)
		self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
		self.title = "TesSoMe"
		self.textView.tintColor = UIColor.globalTintColor()

		self.navigationController?.navigationBar.backgroundColor = UIColor.globalTintColor()
		
		selectTopicViewController.tableView.delegate = self
		selectTopicViewController.tableView.dataSource = self

		topicConfig.title = NSLocalizedString("Topic", comment: "Topic")
		topicConfig.value = "\(topicId + 99)"
		topicConfig.valuePending = true
		
		topicConfig.tapHandler = {
			self.pushConfigurationViewController(self.selectTopicViewController)
		}
		
		let item = self.extensionContext!.inputItems[0] as NSExtensionItem
		let itemProvider = item.attachments![0] as NSItemProvider
		
		if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as NSString) {
			self.textView.text = "Image.jpg"
			self.isContentValid()
		} else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as NSString) {
			itemProvider.loadItemForTypeIdentifier(kUTTypeFileURL as NSString, options: nil, completionHandler: { (item, error) in
				let fileName = (item as NSURL).lastPathComponent
				dispatch_sync(dispatch_get_main_queue(), {
					self.textView.text = fileName
					self.isContentValid()
				})
			})
		} else if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
			isFileShare = false
			self.isContentValid()
		}
		
		let serviceName = "TesSoMe"
		let accounts = SSKeychain.accountsForService(serviceName)
		if accounts != nil {
			let account = accounts.last as? NSDictionary
			let username = account!["acct"] as String!
			let password = SSKeychain.passwordForService(serviceName, account: username)
			self.apiManager.signIn(username: username, password: password, onSuccess:
				{
					self.apiManager.getTopic(onSuccess:
						{ data in
							self.topics = data["data"] as [NSDictionary]
							self.selectTopicViewController.tableView.reloadData()
							self.topicConfig.valuePending = false
						}
						, onFailure:
						{ err in
							self.topicConfig.valuePending = false
							self.topicConfig.value = NSLocalizedString("Failed to connect to server", comment: "Failed to connect to server")
							self.topicConfig.tapHandler = nil
						}
					)
				}
				, onFailure:
				{ err in
					self.topicConfig.valuePending = false
					self.topicConfig.value = NSLocalizedString("Failed to connect to server", comment: "Failed to connect to server")
					self.topicConfig.tapHandler = nil
				}
			)
		}
	}
	
	override func isContentValid() -> Bool {
		if let currentMessage = contentText {
			let currentMessageLength = countElements(currentMessage)
			if isFileShare {
				self.charactersRemaining = self.tesso_maxFilenameLimit - currentMessageLength
			} else {
				self.charactersRemaining = self.tesso_maxCharactersLimit - currentMessageLength
			}
			if Int(currentMessageLength) == 0 || Int(self.charactersRemaining) < 0 {
				return false
			}
		}
		return true
	}
	
	func saveDataToTmp(data: NSData, fileName: String) -> NSURL! {
		let fileManager = NSFileManager.defaultManager()
		var tmpDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
		let now = NSDate()
		var err: NSError? = nil
		tmpDir = tmpDir.URLByAppendingPathComponent("\(now.timeIntervalSince1970)")
		fileManager.createDirectoryAtURL(tmpDir, withIntermediateDirectories: true, attributes: nil, error: &err)
		if err == nil {
			let fileURLtoPost = tmpDir.URLByAppendingPathComponent(fileName)
			fileManager.createFileAtPath(fileURLtoPost.relativePath!, contents: data, attributes: nil)
			return fileURLtoPost
		}
		return nil
	}

	override func didSelectPost() {
		let item = self.extensionContext!.inputItems[0] as NSExtensionItem
		let itemProvider = item.attachments![0] as NSItemProvider
		
		if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeFileURL as NSString) {
			itemProvider.loadItemForTypeIdentifier(kUTTypeFileURL as NSString, options: nil, completionHandler: { (item, error) in
				let fileURL = item as NSURL
				let data = NSData(contentsOfURL: fileURL)
				let fileName = self.contentText
				
				if let fileURL = self.saveDataToTmp(data, fileName: fileName) {
					self.apiManager.uploadFile(fileURL: fileURL, onSuccess:
						{ data in
							NSLog("Share Extension: Success (File share)")
							self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
						}
						, onFailure:
						{ err in
							NSLog("Share Extension: Post Failed (File share), %@", err.localizedDescription)
							self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
						}
						)(topicid: self.topicId)
				} else {
					NSLog("Share Extension: Post Failed (File share), Can't save file")
					self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
				}
			})
		} else if itemProvider.hasItemConformingToTypeIdentifier(kUTTypeImage as NSString) {
			itemProvider.loadItemForTypeIdentifier(kUTTypeImage as NSString, options: nil, completionHandler: { (item, error) in
				let imageURL = item as NSURL
				let imgData = NSData(contentsOfURL: imageURL)
				let image = UIImage(data: imgData)
				let data = UIImageJPEGRepresentation(image, 0.8)
				let fileName = self.contentText
				
				if let fileURL = self.saveDataToTmp(data, fileName: fileName) {
					self.apiManager.uploadFile(fileURL: fileURL, onSuccess:
						{ data in
							NSLog("Share Extension: Success (Image share)")
							self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
						}
						, onFailure:
						{ err in
							NSLog("Share Extension: Post Failed (Image share), %@", err.localizedDescription)
							self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
						}
						)(topicid: self.topicId)
				} else {
					NSLog("Share Extension: Post Failed (Image share), Can't save file")
					self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
				}
			})
		} else if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
			itemProvider.loadItemForTypeIdentifier("public.url", options: nil, completionHandler: { (item, error) in
				let url = item as NSURL
				var urlString = url.absoluteString!.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
				
				self.apiManager.sendMessage(topicid: self.topicId, message: "\(self.contentText) \n\(urlString)", onSuccess:
					{ data in
						NSLog("Share Extension: Success (URL share)")
						self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
					}
					, onFailure:
					{ err in
						NSLog("Share Extension: Post Failed (URL share), %@", err.localizedDescription)
						self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
					}
				)

				
			})
		} else {
			apiManager.sendMessage(topicid: topicId, message: self.contentText, onSuccess:
				{ data in
					NSLog("Share Extension: Success")
					self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
				}
				, onFailure:
				{ err in
					NSLog("Share Extension: Post Failed, %@", err.localizedDescription)
					self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
				}
			)
		}
		
	}

	override func configurationItems() -> [AnyObject]! {
		return [topicConfig]
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return topics.count
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = UITableViewCell()
		if indexPath.row >= topics.count {
			return cell
		}
		let topic = topics[indexPath.row]
		let topicNumber = (topic["id"] as String!).toInt()! + 99
		let titleAttributedText = NSMutableAttributedString(string: "\(topicNumber) ", attributes: [NSForegroundColorAttributeName: UIColor.globalTintColor()])
		titleAttributedText.appendAttributedString(NSAttributedString(string: topic["data"] as String!))
		cell.textLabel?.attributedText = titleAttributedText
		return cell
	}
	
	func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
		popConfigurationViewController()
		
		let topic = topics[indexPath.row]
		self.topicId = (topic["id"] as String!).toInt()!
		self.topicConfig.value = "\(topicId + 99)"
		
		return indexPath
	}
}