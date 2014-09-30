//
//  ReplyViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/30.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ReplyViewController: UITableViewController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	let apiManager = TessoApiManager()
	
	var replies: [TesSoMeData] = []
	var latestMessageId = 0
	var messageFontSize = 0.0 as CGFloat
	var withBadge: Bool = true
	var timestampIsRelative: Bool = true
	
	var updateTimestampTimer: NSTimer? = nil
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.tableView.estimatedRowHeight = 90.5
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		self.refreshControl?.backgroundColor = UIColor.globalTintColor()
		self.refreshControl?.tintColor = UIColor.whiteColor()
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.getReplies()
		})
		
		self.refreshControl!.addTarget(self, action: Selector("updateReplies"), forControlEvents: .ValueChanged)
		
		self.tableView.addInfiniteScrollingWithActionHandler(loadOlderReplies)
		
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem()
	}
	
	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		messageFontSize = CGFloat(ud.floatForKey("fontSize"))
		withBadge = ud.boolForKey("badge")
		timestampIsRelative = ud.boolForKey("relativeTimestamp")
		if replies.count > 0 {
			updateReplies()
		}
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
		return replies.count
	}
	
	
	override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell = tableView.dequeueReusableCellWithIdentifier("MessageCell", forIndexPath: indexPath) as TimelineMessageCell
		let data = replies[indexPath.row]
		// Configure the cell...
		data.setDataToCell(&cell, withFontSize: messageFontSize, withBadge: withBadge)
		cell.updateTimestamp(relative: timestampIsRelative)
		return cell
	}
	
	func refreshUpdatedDate() {
		let format = NSLocalizedString("'Last update: 'MMM d, h:mm:ss a", comment: "Updated date format")
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = format
		let now = NSDate()
		
		let refreshed = NSMutableAttributedString(string: dateFormatter.stringFromDate(now), attributes: [NSForegroundColorAttributeName: UIColor(white: 0.8, alpha: 1.0)])
		self.refreshControl?.attributedTitle = refreshed
	}
	
	func getReplies() {
		apiManager.getSearchResult(tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: TessoApiManager.TesSoMeSearchType.All, onSuccess:
			{ data in
				self.refreshUpdatedDate()
				
				let timeline = TesSoMeData.tlFromResponce(data)
				for post in timeline as [NSDictionary] {
					self.replies.append(TesSoMeData(data: post))
				}
				self.latestMessageId = self.replies.first!.statusid
				self.tableView.reloadData()
				
				self.refreshControl?.endRefreshing()
				
				self.updateTimestampTimer = NSTimer(timeInterval:Double(1.0), target: self, selector: Selector("updateTimestamp"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(self.updateTimestampTimer!, forMode: NSRunLoopCommonModes)
				
			}
			, onFailure: nil
		)
	}
	
	func loadOlderReplies() {
		let oldestMessageId = replies.last?.statusid
		apiManager.getSearchResult(maxid: oldestMessageId, tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: TessoApiManager.TesSoMeSearchType.All, onSuccess:
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
					let insertIndex = self.replies.count
					timeline.removeAtIndex(0)
					for (i, post) in enumerate(timeline) {
						self.replies.insert(TesSoMeData(data: post), atIndex: insertIndex + i)
						path.append(NSIndexPath(forRow: insertIndex + i, inSection: 0))
					}
					
					dispatch_sync(dispatch_get_main_queue(), {
						self.tableView.reloadData()
						self.tableView.infiniteScrollingView.stopAnimating()
					})
				})
			}
			, onFailure: nil
		)
	}
	
	func updateTimestamp() {
		var cells: [TimelineMessageCell] = tableView.visibleCells() as [TimelineMessageCell]
		for cell in cells {
			cell.updateTimestamp(relative: timestampIsRelative)
		}
	}
	
	func clearUnreadMark() {
		if self.tableView.contentOffset.y < -30.0 {
			self.navigationController?.tabBarItem.title = ""
		}
	}
		
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
	
	func insertCellAtPaths(paths: [NSIndexPath]) {
		// self.tableview.beginUpdates()
		
		if paths.count == 0 {
			return
		}
		
		self.tableView.insertRowsAtIndexPaths(paths, withRowAnimation: .Top)
		
		// self.tableview.endUpdates()
	}
	
	func updateReplies() {
		apiManager.getSearchResult(sinceid: latestMessageId, tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: TessoApiManager.TesSoMeSearchType.All, onSuccess:
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
						self.replies.insert(TesSoMeData(data: post), atIndex: 0)
						path.append(NSIndexPath(forRow: i, inSection: 0))
					}
					self.latestMessageId = self.replies.first!.statusid
					
					dispatch_sync(dispatch_get_main_queue(), {
						self.insertCellAtPaths(path)
					})
				})
			}
			, onFailure: nil
		)
	}
	
	
	
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
	// Get the new view controller using [segue destinationViewController].
	// Pass the selected object to the new view controller.
	}
	*/
	
}
