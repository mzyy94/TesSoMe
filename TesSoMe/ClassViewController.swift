//
//  ClassViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/06.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ClassViewController: UIViewController, RDVCalendarViewDelegate, UITableViewDelegate, UITableViewDataSource {
	
	@IBOutlet weak var calendarViewPlace: UIView!
	@IBOutlet weak var classTableView: UITableView!
	
	var calendarView: RDVCalendarView! = nil
	var eventDays: [ClassEvent] = []
	var currentEvent: [ClassEvent] = []
	
	let apiManager = TessoApiManager()
	
    override func viewDidLoad() {
        super.viewDidLoad()

		calendarView = RDVCalendarView()
		calendarView.registerDayCellClass(ClassEventDayCell.self)
		calendarView.delegate = self
		calendarView.showCurrentMonth()
		calendarView.setTranslatesAutoresizingMaskIntoConstraints(false)
		calendarView.monthLabel.textColor = UIColor.whiteColor()
		calendarView.forwardButton.setTitle("", forState: .Normal)
		calendarView.backButton.setTitle("", forState: .Normal)
		
		let calendar = NSCalendar.currentCalendar()
		let todayComponents = calendar.components(NSCalendarUnit.CalendarUnitDay, fromDate: NSDate())
		calendarView.selectDayCellAtIndex(todayComponents.day - 1, animated: false)
		calendarView.selectedDate = NSDate()
		calendarView.selectedDayColor = UIColor.globalTintColor(alpha: 0.7)
		
		self.calendarViewPlace.addSubview(calendarView)
		
		for constraintAttribute: NSLayoutAttribute in [.Width, .Height] {
			self.calendarViewPlace.addConstraint(NSLayoutConstraint(item: self.calendarView, attribute: constraintAttribute, relatedBy: .Equal, toItem: self.calendarViewPlace, attribute: constraintAttribute, multiplier: 1.0, constant: 0))
		}
		
		let swipeToGoForwardMonth = UISwipeGestureRecognizer(target: self, action: Selector("goForward:"))
		swipeToGoForwardMonth.direction = .Left
		calendarView.addGestureRecognizer(swipeToGoForwardMonth)
		
		let swipeToGoBackMonth = UISwipeGestureRecognizer(target: self, action: Selector("goBack:"))
		swipeToGoBackMonth.direction = .Right
		calendarView.addGestureRecognizer(swipeToGoBackMonth)
		
		self.navigationItem.title = calendarView.monthLabel.text
		
		self.classTableView.delegate = self
		self.classTableView.dataSource = self
		
		apiManager.getClass(onSuccess:
			{ data in
				let classes = TesSoMeData.dataFromResponce(data)
				self.eventDays.removeAll(keepCapacity: true)
				self.currentEvent.removeAll(keepCapacity: false)
				
				for event in classes {
					self.eventDays.append(ClassEvent(data: event as NSDictionary))
				}
				
				self.calendarView.reloadData()
				println(self.calendarView.indexForSelectedDayCell())
				self.calendarView.selectDayCellAtIndex(self.calendarView.indexForSelectedDayCell(), animated: false)
			}, onFailure: nil)
		
    }
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return currentEvent.count
	}
	
	func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		let formatter = NSDateFormatter()
		formatter.dateFormat = NSLocalizedString("YYYY/MM/dd", comment: "Class date header format")

		let titleFormat = NSLocalizedString("%@ Classes (%d)", comment: "Class title header format")
		var selectedDate = self.calendarView.selectedDate
		if selectedDate == nil {
			selectedDate = NSDate()
		}
		return NSString(format: titleFormat, formatter.stringFromDate(selectedDate), currentEvent.count)
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let event = currentEvent[indexPath.row]
		let cell = tableView.dequeueReusableCellWithIdentifier("ClassCell", forIndexPath: indexPath) as ClassCell
		
		cell.titleLabel.text = event.title
		
		let formatter = NSDateFormatter()
		formatter.dateFormat = NSLocalizedString("YYYY/MM/dd HH:mm 'Start'", comment: "Class date format")
		cell.dateLabel.text = formatter.stringFromDate(event.date)
		
		cell.userIcon.sd_setImageWithURL(NSURL(string: "https://tesso.pw/img/icons/\(event.username).png"))
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		let event = currentEvent[indexPath.row]
		let cell = tableView.cellForRowAtIndexPath(indexPath) as ClassCell

		let confirmationText = NSLocalizedString("Do you want to set alert?", comment: "Alert confirmation text")
		let alertController = UIAlertController(title: cell.titleLabel.text, message: "\(cell.dateLabel.text!)\n\n\(confirmationText)", preferredStyle: .Alert)
		
		let renameAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler: nil)
		alertController.addAction(renameAction)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)

		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	func goForward(sender: UISwipeGestureRecognizer) {
		self.calendarView.showNextMonth()
		self.navigationItem.title = self.calendarView.monthLabel.text
	}
	
	func goBack(sender: UISwipeGestureRecognizer) {
		self.calendarView.showPreviousMonth()
		self.navigationItem.title = self.calendarView.monthLabel.text
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	func calendarView(calendarView: RDVCalendarView!, configureDayCell dayCell: RDVCalendarDayCell!, atIndex index: Int) {
		let cell = dayCell as ClassEventDayCell
		for event in eventDays {
			if event.dateComponents.year == calendarView.month.year &&
				event.dateComponents.month == calendarView.month.month &&
				event.dateComponents.day == index + 1 {
				cell.notificationView.hidden = false
			}
		}
	}
	
	func calendarView(calendarView: RDVCalendarView!, didSelectCellAtIndex index: Int) {
		currentEvent.removeAll(keepCapacity: false)
		for event in eventDays {
			if event.dateComponents.year == calendarView.month.year &&
				event.dateComponents.month == calendarView.month.month &&
				event.dateComponents.day == index + 1 {
					currentEvent.append(event)
			}
		}
		classTableView.reloadData()
	}
	
}
