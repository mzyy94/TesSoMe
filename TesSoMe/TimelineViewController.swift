//
//  TimelineViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TimelineViewController: SuperTimelineViewController, UITabBarControllerDelegate {
	let apiManager = TessoApiManager()
	
	@IBOutlet weak var scrollView: UIScrollView!
	@IBOutlet weak var pageControl: UIPageControl!

	var appearing = false
	
	override func getTimeline() {
		let topic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		apiManager.getTimeline(topicid: topic, onSuccess:
			{ data in
				self.refreshUpdatedDate()
				
				let timeline = TesSoMeData.tlFromResponce(data)
				for post in timeline as [NSDictionary] {
					self.messages.append(TesSoMeData(data: post))
				}
				self.latestMessageId = self.messages.first!.statusId
				self.tableView.reloadData()
				
				self.refreshControl?.endRefreshing()
				
				self.setUpdateTimelineFetchTimer()
				self.updateTimestampTimer = NSTimer(timeInterval:Double(1.0), target: self, selector: Selector("updateTimestamp"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(self.updateTimestampTimer!, forMode: NSRunLoopCommonModes)
				self.endUpdating()
			}
			, onFailure: failureAction
		)
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		self.tabBarController!.delegate = self
		self.scrollView.delegate = self
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("insertCellWhenActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
		checkUpdate()
	}
	
	func setTopicTitle(topics: [NSDictionary]) {
		let currentTopic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		var leftItem: UILabel! = nil
		
		for (index, topic) in enumerate(topics as [NSDictionary]) {
			let title = topic["data"] as String
			let topicId = (topic["id"] as String).toInt()!
			
			var attributedText = NSMutableAttributedString(string: "\(topicId + 99) ", attributes: [NSForegroundColorAttributeName: UIColor.globalTintColor()]) as NSMutableAttributedString
			
			attributedText.appendAttributedString(NSAttributedString(string: title))
			
			let label = UILabel()
			label.attributedText = attributedText
			label.textAlignment = .Center
			label.tag = topicId
			
			label.setTranslatesAutoresizingMaskIntoConstraints(false)
			label.frame = self.scrollView.frame
			self.scrollView.addSubview(label)
			
			for constraintAttribute: NSLayoutAttribute in [.Width, .Height, .Top, .Bottom] {
				self.scrollView.addConstraint(NSLayoutConstraint(item: label, attribute: constraintAttribute, relatedBy: .Equal, toItem: self.scrollView, attribute: constraintAttribute, multiplier: 1.0, constant: 0))
			}
			
			if leftItem == nil {
				self.scrollView.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: .Equal, toItem: self.scrollView, attribute: .Left, multiplier: 1.0, constant: 0.0))
			} else {
				self.scrollView.addConstraint(NSLayoutConstraint(item: label, attribute: NSLayoutAttribute.Left, relatedBy: .Equal, toItem: leftItem, attribute: .Right, multiplier: 1.0, constant: 0.0))
			}
			
			leftItem = label
			self.pageControl.numberOfPages = index + 1
			
			if topicId == currentTopic {
				self.pageControl.currentPage = index
			}
		}
		self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width * CGFloat(topics.count), height: self.scrollView.frame.height)
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		if self.scrollView.contentSize.width == 0 {
			self.scrollView.contentSize = CGSize(width: self.scrollView.frame.width * CGFloat(self.pageControl.numberOfPages), height: self.scrollView.frame.height)
			
			var rect = self.scrollView.frame
			rect.origin = CGPoint(x: rect.width * CGFloat(self.pageControl.currentPage), y: 0)
			self.scrollView.scrollRectToVisible(rect, animated: false)
		}
	}
	
	func checkUpdate() {
		let currentVersion = (NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as NSString).doubleValue// as Double
		
		let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		sessionConfig.HTTPShouldSetCookies = true
		let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
		req.responseSerializer.acceptableContentTypes = NSSet(object: "text/plain")
		req.GET("https://tesso.pw/mem/mzyy94/version.json", parameters: nil, success:
			{ res, data in
				let newVersion = data["current"] as Double
				
				if newVersion > currentVersion {
					let newVersionTitle = NSLocalizedString("New Version Available", comment: "new version notification title")
					let newVersionMessage = NSLocalizedString("New Version %.2f is available. Update now.", comment: "new version notification message")
					let notificationView = MPGNotification(title: newVersionTitle, subtitle: NSString(format: newVersionMessage, newVersion), backgroundColor: UIColor(red: 0.3, green: 1.0, blue: 0.3, alpha: 1.0), iconImage: nil)
					notificationView.animationType = .Drop
					notificationView.setButtonConfiguration(.TwoButton, withButtonTitles: [NSLocalizedString("Update", comment: "Update"), NSLocalizedString("Later", comment: "Later")])
					notificationView.swipeToDismissEnabled = false
					notificationView.duration = 5.0
					notificationView.buttonHandler = {
						notification, buttonIndex in
						if buttonIndex == notification.firstButton.tag {
							self.app.openURL(NSURL(string: data["url"] as String)!)
						}
					}
					notificationView.show()
				}
			}
			, failure: nil
		)

	}
	
	func insertCellWhenActive() {
		if !appearing || stackedCellPaths.count == 0 || isScrolling {
			return
		}
		insertCellAtPaths(stackedCellPaths)
		stackedCellPaths.removeAll(keepCapacity: false)
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		appearing = true
		insertCellWhenActive()
	}
	
	override func viewDidDisappear(animated: Bool) {
		super.viewDidDisappear(animated)
		appearing = false
	}

	func tabBarController(tabBarController: UITabBarController!, didSelectViewController viewController: UIViewController!) {
		let topIndexPath = NSIndexPath(forRow: 0, inSection: 0)
		if appearing && self.parentViewController == viewController && self.tableView.numberOfRowsInSection(0) > 0 {
			self.tableView.scrollToRowAtIndexPath(topIndexPath, atScrollPosition: .Top, animated: true)
		}
	}

	override func updateTimeline() {
		let topic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		apiManager.getTimeline(topicid: topic, sinceid: latestMessageId, onSuccess:
			{ data in
				self.refreshUpdatedDate()
				if self.refreshControl!.refreshing {
					self.refreshControl?.endRefreshing()
				}
				
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					let timeline = TesSoMeData.tlFromResponce(data)
					if timeline.count == 0 {
						return
					}
					
					var path:[NSIndexPath] = []
					let insertedCellCount = timeline.count
					
					for (i, post) in enumerate((timeline as [NSDictionary]).reverse()) {
						let tessomeData = TesSoMeData(data: post)
						if tessomeData.isReplyTo(self.appDelegate.usernameOfTesSoMe!) {
							self.appDelegate.notifyMessage(tessomeData.message, from: tessomeData.username, statusid: tessomeData.statusId, topicid: tessomeData.topicid)
						}
						self.messages.insert(tessomeData, atIndex: 0)
						path.append(NSIndexPath(forRow: i, inSection: 0))
					}
					self.latestMessageId = self.messages.first!.statusId
					
					if self.isScrolling || self.app.applicationState != .Active {
						let newStackedCellPaths = path + self.stackedCellPaths
						self.stackedCellPaths = newStackedCellPaths
						let topOffset = self.tableView.contentOffset.y
						if topOffset > -30.0 {
							dispatch_sync(dispatch_get_main_queue(), {
								self.navigationController!.tabBarItem.title = "●"
							})
						}
						return
					}
					
					dispatch_sync(dispatch_get_main_queue(), {
						self.insertCellAtPaths(path)
						self.endUpdating()
					})
				})
			}
			, onFailure: failureAction
		)
	}
	
	override func loadOlderTimeline() {
		if isUpdating {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("loadOlderTimeline"), userInfo: nil, repeats: false)
			return
		}
		let topic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		let oldestMessageId = messages.last?.statusId
		apiManager.getTimeline(topicid: topic, maxid: oldestMessageId, onSuccess:
			{ data in
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					var timeline = TesSoMeData.tlFromResponce(data) as [NSDictionary]
					if timeline.count <= 1 { // No more messages
						dispatch_sync(dispatch_get_main_queue(), {
							self.tableView.infiniteScrollingView.stopAnimating()
							//	self.tableView.showsInfiniteScrolling = false
							self.tableView.infiniteScrollingView.enabled = false
						})
						return
					}
					
					var path:[NSIndexPath] = []
					let insertIndex = self.messages.count
					timeline.removeAtIndex(0)
					for (i, post) in enumerate(timeline) {
						self.messages.insert(TesSoMeData(data: post), atIndex: insertIndex + i)
						path.append(NSIndexPath(forRow: insertIndex + i, inSection: 0))
					}
					
					dispatch_sync(dispatch_get_main_queue(), {
						self.tableView.reloadData()
						self.tableView.infiniteScrollingView.stopAnimating()
						self.endUpdating()
					})
				})
			}
			, onFailure: failureAction
		)
	}
	
	func failureAction(err: NSError) {
		self.refreshControl?.endRefreshing()
		
		let notification = MPGNotification(title: NSLocalizedString("Failed to load timeline", comment: "Failed to load timeline"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
		notification.duration = 5.0
		notification.animationType = .Drop
		notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
		notification.swipeToDismissEnabled = false
		notification.show()
		endUpdating()
	}
	
	func resetTopicTitle() {
		let currentTopic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		
		for (index, topicTitleLabel) in enumerate(self.scrollView.subviews as [UILabel]) {
			if topicTitleLabel.tag == currentTopic {
				var rect = self.scrollView.frame
				rect.origin = CGPoint(x: rect.width * CGFloat(index), y: 0)
				self.scrollView.scrollRectToVisible(rect, animated: true)
				self.pageControl.currentPage = index
				break
			}
		}
		resetTimeline()
	}
	
	func resetTimeline() {
		updateTimelineFetchTimer?.invalidate()
		updateTimestampTimer?.invalidate()
		messages = []
		self.tableView.infiniteScrollingView.enabled = true
		getTimeline()
	}

	func setTopicTitlePage() {
		let page = Int(scrollView.contentOffset.x / scrollView.frame.width)
		if page == self.pageControl.currentPage {
			return
		}
		self.pageControl.currentPage = page
		let topic = (scrollView.subviews[page] as UILabel).tag
		let topicMenuController = appDelegate.frostedViewController?.menuViewController as TopicMenuViewController
		topicMenuController.currentTopic = topic
		
		resetTimeline()
	}
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		if NSStringFromClass(scrollView.dynamicType) == "UIScrollView" {
			return
		}
		super.scrollViewDidScroll(scrollView)
	}
	
	override func scrollViewDidScrollToTop(scrollView: UIScrollView) {
		if NSStringFromClass(scrollView.dynamicType) == "UIScrollView" {
			return
		}
		super.scrollViewDidScrollToTop(scrollView)
	}
	
	override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		if NSStringFromClass(scrollView.dynamicType) == "UIScrollView" {
			return
		}
		super.scrollViewWillBeginDragging(scrollView)
	}
	
	override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if NSStringFromClass(scrollView.dynamicType) == "UIScrollView" {
			if decelerate {
				setTopicTitlePage()
			}
			return
		}
		super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
		if !decelerate && isScrolling && self.app.applicationState == .Active {
			isScrolling = false
			insertCellWhenActive()
		}
	}
	
	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		if NSStringFromClass(scrollView.dynamicType) == "UIScrollView" {
			setTopicTitlePage()
		}
		super.scrollViewDidEndDecelerating(scrollView)
		if isScrolling && self.app.applicationState == .Active {
			isScrolling = false
			insertCellWhenActive()
		}
	}
	
}
