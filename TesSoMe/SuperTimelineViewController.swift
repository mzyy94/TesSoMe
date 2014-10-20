//
//  SuperTimelineViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/01.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class SuperTimelineViewController: UITableViewController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	
	var messages: [TesSoMeData] = []
	var stackedCellPaths: [NSIndexPath] = []
	var latestMessageId: Int = 0
	var messageFontSize: CGFloat = 0.0
	var withBadge: Bool = true
	var withReplyIcon: Bool = false
	var withImagePreview: Bool = false
	var timestampIsRelative: Bool = true
	
	var updateTimelineMethod: (() -> Void) = {}
	
	var updateTimelineFetchTimer: NSTimer? = nil
	var updateTimestampTimer: NSTimer? = nil
	
	var isUpdating = false
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.tableView.estimatedRowHeight = 90.5
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		self.refreshControl?.backgroundColor = UIColor.globalTintColor()
		self.refreshControl?.tintColor = UIColor.whiteColor()
		
		self.updateTimelineMethod = getTimeline
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.updateTimelineMethod()
		})
		
		self.refreshControl!.addTarget(self, action: Selector("manualUpdateTimeline"), forControlEvents: .ValueChanged)
		
		self.tableView.addInfiniteScrollingWithActionHandler(loadOlderTimeline)
		self.tableView.infiniteScrollingView.enabled = false
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		messageFontSize = CGFloat(ud.floatForKey("fontSize"))
		withBadge = ud.boolForKey("badge")
		withImagePreview = ud.boolForKey("imagePreview")
		withReplyIcon = ud.boolForKey("replyIcon")
		timestampIsRelative = ud.boolForKey("relativeTimestamp")
		self.tableView.reloadData()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		// #warning Potentially incomplete method implementation.
		// Return the number of sections.
		return 1
	}
	
	override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// Return the number of Messages.
		return messages.count
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as TimelineMessageCell
		let data = messages[indexPath.row]
		// Configure the cell...
		data.setDataToCell(&cell, withFontSize: messageFontSize, withBadge: withBadge, withImagePreview: withImagePreview, repliedUsername: appDelegate.usernameOfTesSoMe, withReplyIcon: withReplyIcon)
		cell.updateTimestamp(relative: timestampIsRelative)
		return cell
	}
	
	func refreshUpdatedDate() {
		let format = NSLocalizedString("'Last update: 'MMM d, h:mm:ss a", comment: "Updated date format")
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = format
		let now = NSDate()
		
		isUpdating = false
		
		let refreshed = NSMutableAttributedString(string: dateFormatter.stringFromDate(now), attributes: [NSForegroundColorAttributeName: UIColor(white: 0.8, alpha: 1.0)])
		self.refreshControl?.attributedTitle = refreshed
	}
	
	func tryUpdateTimeline() {
		if isUpdating {
			if self.refreshControl!.refreshing {
				self.refreshControl?.endRefreshing()
			}
			return
		}
		isUpdating = true
		updateTimelineMethod()
	}
	
	func manualUpdateTimeline() {
		if updateTimelineFetchTimer != nil {
			updateTimelineFetchTimer?.fire()
		} else {
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
				self.tryUpdateTimeline()
			})
		}
	}

	func endUpdating(null: AnyObject? = nil) {
		isUpdating = false
	}
	
	func getTimeline() {
		fatalError("This method must be overridden")
	}
	
	func updateTimeline() {
		fatalError("This method must be overridden")
	}
	
	func loadOlderTimeline() {
		fatalError("This method must be overridden")
	}
	
	func setUpdateTimelineFetchTimer() {
		updateTimelineFetchTimer?.invalidate()
		if self.ud.boolForKey("streaming") {
			let interval = NSTimeInterval(ud.floatForKey("interval"))
			updateTimelineFetchTimer = NSTimer(timeInterval:interval, target: self, selector: Selector("tryUpdateTimeline"), userInfo: nil, repeats: true)
			NSRunLoop.currentRunLoop().addTimer(updateTimelineFetchTimer!, forMode: NSRunLoopCommonModes)
		}
		updateTimelineMethod = updateTimeline
		self.tableView.infiniteScrollingView.enabled = true
	}
	
	func updateTimestamp() {
		var cells = tableView.visibleCells() as [TimelineMessageCell]
		for cell in cells {
			cell.updateTimestamp(relative: timestampIsRelative)
		}
	}
	
	func clearUnreadMark() {
		if self.tableView.contentOffset.y < -30.0 {
			self.navigationController?.tabBarItem.title = ""
		}
	}
	
	var isScrolling = false
	
	override func scrollViewDidScroll(scrollView: UIScrollView) {
		clearUnreadMark()
	}
	
	override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		clearUnreadMark()
	}
	
	override func scrollViewDidScrollToTop(scrollView: UIScrollView) {
		clearUnreadMark()
	}
	
	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		clearUnreadMark()
	}
	
	override func scrollViewWillBeginDragging(scrollView: UIScrollView) {
		isScrolling = true
	}
	
	func insertCellAtPaths(paths: [NSIndexPath]) {
		// self.tableview.beginUpdates()
		
		if paths.count == 0 {
			return
		}
		
		let topOffset = self.tableView.contentOffset.y
		let autoScroll = !(topOffset > -30.0) // more
		
		UIView.setAnimationsEnabled(false)
		self.tableView.insertRowsAtIndexPaths(paths, withRowAnimation: .None)
		
		if autoScroll {
			self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: paths.count, inSection: 0), atScrollPosition: .Top, animated: false)
			UIView.setAnimationsEnabled(true)
			self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition: .Top, animated: true)
		} else {
			self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: paths.count, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
			let currentOffset = self.tableView.contentOffset.y
			let navigationBarHeight = self.navigationController!.navigationBar.frame.height
			
			self.tableView.setContentOffset(CGPointMake(0.0, topOffset + currentOffset + navigationBarHeight), animated: false)
			self.navigationController!.tabBarItem.title = "●"
			UIView.setAnimationsEnabled(true)
		}
		
		// self.tableview.endUpdates()
	}
	
}
