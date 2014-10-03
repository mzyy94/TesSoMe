//
//  SearchResultViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/03.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class SearchResultViewController: SuperTimelineViewController {
	let apiManager = TessoApiManager()
	
	var type: TesSoMeSearchType = .All
	var username: String! = nil
	var tag: String! = nil
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func getTimeline() {
		apiManager.getSearchResult(tag: tag, username: username, type: type, onSuccess:
			{ data in
				self.refreshUpdatedDate()
				
				let timeline = TesSoMeData.tlFromResponce(data)
				if timeline.count == 0 {
					let errMsg = NSLocalizedString("No result.", comment: "No result.")
					let errorDetails = NSDictionary.dictionaryWithObjects([errMsg], forKeys: [NSLocalizedDescriptionKey], count: 1)
					let err = NSError(domain: "API", code: 300, userInfo: errorDetails)
					self.failureAction(err)
					return
				}
				for post in timeline as [NSDictionary] {
					self.messages.append(TesSoMeData(data: post))
				}
				self.latestMessageId = self.messages.first!.statusId
				self.tableView.reloadData()
				
				self.refreshControl?.endRefreshing()
				
				self.updateTimelineMethod = self.updateTimeline
				self.tableView.infiniteScrollingView.enabled = true

				self.updateTimestampTimer = NSTimer(timeInterval:Double(1.0), target: self, selector: Selector("updateTimestamp"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(self.updateTimestampTimer!, forMode: NSRunLoopCommonModes)
				
			}
			, onFailure: failureAction
		)
	}
	
	override func updateTimeline() {
		apiManager.getSearchResult(sinceid: latestMessageId, tag: tag, username: username, type: type, onSuccess:
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
			, onFailure: failureAction
		)
	}
	
	override func loadOlderTimeline() {
		let oldestMessageId = messages.last?.statusId
		apiManager.getSearchResult(maxid: oldestMessageId, tag: tag, username: username, type: type, onSuccess:
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
			, onFailure: failureAction
		)
	}
	
	func failureAction(err: NSError) {
		self.refreshControl?.endRefreshing()
		
		let notification = MPGNotification(title: NSLocalizedString("Failed to load timeline", comment: "Failed to load timeline"), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
		notification.duration = 5.0
		notification.animationType = .Drop
		notification.setButtonConfiguration(.ZeroButtons, withButtonTitles: nil)
		notification.show()
	}
	


	
	override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
