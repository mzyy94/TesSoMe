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
		NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("insertCellWhenActive"), name: UIApplicationDidBecomeActiveNotification, object: nil)
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
		if isUpdating {
			let timer = NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: Selector("updateTimeline"), userInfo: nil, repeats: false)
			return
		}
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
						if topOffset > -60.0 {
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
	
	func resetTimeline() {
		updateTimelineFetchTimer?.invalidate()
		updateTimestampTimer?.invalidate()
		messages = []
		self.tableView.infiniteScrollingView.enabled = true
		getTimeline()
	}

	
	override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		super.scrollViewDidEndDragging(scrollView, willDecelerate: decelerate)
		if !decelerate && isScrolling && self.app.applicationState == .Active {
			isScrolling = false
			insertCellWhenActive()
		}
	}
	
	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		super.scrollViewDidEndDecelerating(scrollView)
		if isScrolling && self.app.applicationState == .Active {
			isScrolling = false
			insertCellWhenActive()
		}
	}
	
}
