//
//  TimelineViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TimelineViewController: UITableViewController {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()
	let apiManager = TessoApiManager()

	var messages: [TesSoMeData] = []
	var latestMessageId = 0
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		let nib = UINib(nibName: "TimelineMessageCell", bundle: nil)
		self.tableView.registerNib(nib, forCellReuseIdentifier: "MessageCell")
		
		self.tableView.estimatedRowHeight = 90.5
		self.tableView.rowHeight = UITableViewAutomaticDimension
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
			self.getTimeline()
		})
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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
		data.setDataToCell(&cell)
		cell.updateTimestamp()
        return cell
    }

	func getTimeline() {
		let topic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		apiManager.getTimeline(topicid: topic, onSuccess:
			{ data in

				let timeline = TesSoMeData.tlFromResponce(data)
				for post in timeline as [NSDictionary] {
					self.messages.append(TesSoMeData(data: post))
				}
				self.latestMessageId = self.messages.first!.statusid
				self.tableView.reloadData()
				
				let topCell: UITableViewCell? = self.tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as UITableViewCell?

				let updateTimelineFetchTimer = NSTimer(timeInterval:Double(5.0), target: self, selector: Selector("updateTimeline"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(updateTimelineFetchTimer, forMode: NSRunLoopCommonModes)
				let updateTimestampTimer = NSTimer(timeInterval:Double(1.0), target: self, selector: Selector("updateTimestamp"), userInfo: nil, repeats: true)
				NSRunLoop.currentRunLoop().addTimer(updateTimestampTimer, forMode: NSRunLoopCommonModes)

			}
			, onFailure: nil
		)
	}
	
	func updateTimestamp() {
		var cells: [TimelineMessageCell] = tableView.visibleCells() as [TimelineMessageCell]
		for cell in cells {
			cell.updateTimestamp()
		}
	}
	
	func updateTimeline() {
		let topic = (appDelegate.frostedViewController?.menuViewController as TopicMenuViewController).currentTopic
		apiManager.getTimeline(topicid: topic, sinceid: latestMessageId, onSuccess:
			{ data in
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
					let timeline = TesSoMeData.tlFromResponce(data)
					if timeline.count == 0 {
						return
					}
					
					var path:[NSIndexPath] = []
					
					for (i, post) in enumerate((timeline as [NSDictionary]).reverse()) {
						self.messages.insert(TesSoMeData(data: post), atIndex: 0)
						path.append(NSIndexPath(forRow: i, inSection: 0))
					}
					self.latestMessageId = self.messages.first!.statusid
					
					let topOffset = self.tableView.contentOffset.y
					let autoScroll = !(topOffset > -40.0) // more
					
					dispatch_sync(dispatch_get_main_queue(), {
						// self.tableview.beginUpdates()
						
						UIView.setAnimationsEnabled(false)
						self.tableView.insertRowsAtIndexPaths(path, withRowAnimation: .None)
						
						if autoScroll {
							var offsetDiff = 0.0 as CGFloat
							
							for p in path {
								let cell: UITableViewCell? = self.tableView.cellForRowAtIndexPath(p) as UITableViewCell?
								offsetDiff += cell!.frame.height
							}
							
							self.tableView.setContentOffset(CGPointMake(0.0, topOffset + offsetDiff), animated: false)
							UIView.setAnimationsEnabled(true)
							self.tableView.setContentOffset(CGPointMake(0.0, -64.0), animated: true)
						} else {
							self.navigationController!.tabBarItem.title = "●"
							UIView.setAnimationsEnabled(true)
						}

						// self.tableview.endUpdates()
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
