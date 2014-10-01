//
//  ReplyViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/30.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ReplyViewController: SuperTimelineViewController {
	let apiManager = TessoApiManager()

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
		if messages.count > 0 {
			updateTimeline()
		}
	}
	
	override func getTimeline() {
		apiManager.getSearchResult(tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: .All, onSuccess:
			{ data in
				self.refreshUpdatedDate()
				
				let timeline = TesSoMeData.tlFromResponce(data)
				for post in timeline as [NSDictionary] {
					self.messages.append(TesSoMeData(data: post))
				}
				self.latestMessageId = self.messages.first!.statusId
				self.tableView.reloadData()
				
				self.refreshControl?.endRefreshing()
				
				self.updateTimestampTimer = NSTimer(timeInterval:Double(1.0), target: self, selector: Selector("updateTimestamp"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(self.updateTimestampTimer!, forMode: NSRunLoopCommonModes)
				
			}
			, onFailure: nil
		)
	}
	
	override func updateTimeline() {
		apiManager.getSearchResult(sinceid: latestMessageId, tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: .All, onSuccess:
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
						self.messages.insert(TesSoMeData(data: post), atIndex: 0)
						path.append(NSIndexPath(forRow: i, inSection: 0))
					}
					self.latestMessageId = self.messages.first!.statusId
					
					dispatch_sync(dispatch_get_main_queue(), {
						self.tableView.insertRowsAtIndexPaths(path, withRowAnimation: .Top)
					})
				})
			}
			, onFailure: nil
		)
	}

	override func loadOlderTimeline() {
		let oldestMessageId = messages.last?.statusId
		apiManager.getSearchResult(maxid: oldestMessageId, tag: "at_\(appDelegate.usernameOfTesSoMe!)", type: .All, onSuccess:
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
					})
				})
			}
			, onFailure: nil
		)
	}
	
}
