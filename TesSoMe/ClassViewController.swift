//
//  ClassViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/06.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ClassViewController: UIViewController, RDVCalendarViewDelegate, UITableViewDelegate, UITableViewDataSource {
	
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	
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
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: Selector("createNewClass"))
		
		self.classTableView.delegate = self
		self.classTableView.dataSource = self
		
		getClass()
		
		let updateClassTimer = NSTimer(timeInterval: 60*60, target: self, selector: Selector("getClass"), userInfo: nil, repeats: true)
		NSRunLoop.currentRunLoop().addTimer(updateClassTimer, forMode: NSRunLoopCommonModes)

    }
	
	func getClass() {
		apiManager.getClass(onSuccess:
			{ data in
				let classes = TesSoMeData.dataFromResponce(data)
				self.eventDays.removeAll(keepCapacity: true)
				self.currentEvent.removeAll(keepCapacity: false)
				
				
				let year = self.calendarView.month.year
				let month = self.calendarView.month.month
				let day = self.calendarView.indexForSelectedDayCell() + 1
				
				for event in classes {
					let classEvent = ClassEvent(data: event as NSDictionary)
					self.eventDays.append(classEvent)
					if classEvent.dateComponents.year == year &&
						classEvent.dateComponents.month == month &&
						classEvent.dateComponents.day == day {
							self.currentEvent.append(classEvent)
					}
				}
				
				self.calendarView.reloadData()
				self.classTableView.reloadData()
			}, onFailure: nil)
	}
	
	func createNewClass() {
		var classname: String! = nil
		
		let alertController = UIAlertController(title: NSLocalizedString("Create New Class", comment: "Create New Class on AlertView"), message: NSLocalizedString("Please type a class name.", comment: "Please type a class name."), preferredStyle: .Alert)
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
		alertController.addAction(cancelAction)
		
		let gotoNext = UIAlertAction(title: NSLocalizedString("Next", comment: "Next on AlertView"), style: .Default) {
			action in
			let textField = alertController.textFields?.first as UITextField
			classname = textField.text

			RMDateSelectionViewController.setLocalizedTitleForSelectButton(NSLocalizedString("Create", comment: "Create"))

			let dateFormatter = NSDateFormatter()
			dateFormatter.dateFormat = "YYYY-MM-dd HH"
			let startDate =	dateFormatter.dateFromString(dateFormatter.stringFromDate(NSDate()))
			
			let dateSelectionViewController = RMDateSelectionViewController.dateSelectionController()
			dateSelectionViewController.title = NSLocalizedString("Choose date to set class.", comment: "Choose date to set class.")
			dateSelectionViewController.hideNowButton = true
			dateSelectionViewController.datePicker.datePickerMode = UIDatePickerMode.DateAndTime
			dateSelectionViewController.datePicker.minimumDate = startDate
			dateSelectionViewController.disableBouncingWhenShowing = true
			dateSelectionViewController.disableBlurEffects = true
			dateSelectionViewController.showWithSelectionHandler(
				{ viewController, date in
					self.apiManager.addClass(date: date, text: classname, onSuccess:
						{ data in
							let okAlertController = UIAlertController(title: NSLocalizedString("Success", comment: "Success"), message: NSLocalizedString("Creating New Class Succeeded", comment: "Creating New Class Succeeded"), preferredStyle: .Alert)

							let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Cancel, handler: nil)
							okAlertController.addAction(okAction)

							self.presentViewController(okAlertController, animated: true, completion: nil)
							self.getClass()
						}
						, onFailure:
						{ err in
							let errAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: err.localizedDescription, preferredStyle: .Alert)
							
							let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Cancel, handler: nil)
							errAlertController.addAction(okAction)
							
							self.presentViewController(errAlertController, animated: true, completion: nil)
						}
					)
				}
				, andCancelHandler:
				{ viewController in
				}
			)
		}
		alertController.addAction(gotoNext)
		
		alertController.addTextFieldWithConfigurationHandler(
			{ textField in
			}
		)
		
		self.presentViewController(alertController, animated: true, completion: nil)
		
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
		
		for notification in app.scheduledLocalNotifications as [UILocalNotification] {
			if notification.category! == "CLASS_CATEGORY" && notification.userInfo!["date"] as NSDate == event.date {
				cell.alarmIcon.hidden = false
				break
			}
		}
		
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

		if cell.alarmIcon.hidden { // Not set notification
			let confirmationText = NSLocalizedString("Do you want to set alert?", comment: "Alert confirmation text")
			let alertController = UIAlertController(title: cell.titleLabel.text, message: "\(cell.dateLabel.text!)\n\n\(confirmationText)", preferredStyle: .Alert)
			
			let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
			alertController.addAction(cancelAction)
			
			let setClassNotificationAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler:
				{ action in
					self.appDelegate.setClassAlert(event.title, date: event.date)
					cell.alarmIcon.hidden = false
				}
			)
			alertController.addAction(setClassNotificationAction)
			
			self.presentViewController(alertController, animated: true, completion: nil)
	
		} else { // Already set notification
			let confirmationText = NSLocalizedString("Do you want to remove alert?", comment: "Alert confirmation text (remove class notification)")
			let alertController = UIAlertController(title: cell.titleLabel.text, message: "\(cell.dateLabel.text!)\n\n\(confirmationText)", preferredStyle: .Alert)
			
			let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
			alertController.addAction(cancelAction)
		
			let removeClassNotificationAction = UIAlertAction(title: NSLocalizedString("Remove", comment: "Remove on AlertView"), style: .Default, handler:
				{ action in
	
					for notification in self.app.scheduledLocalNotifications as [UILocalNotification] {
						if notification.category! == "CLASS_CATEGORY" && notification.userInfo!["date"] as NSDate == event.date {
							self.app.cancelLocalNotification(notification)
							cell.alarmIcon.hidden = true
							break
						}
					}

				}
			)
			alertController.addAction(removeClassNotificationAction)
			
			self.presentViewController(alertController, animated: true, completion: nil)
			
		}
	}
	
	func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		if tableView.cellForRowAtIndexPath(indexPath) == nil {
			return false
		}
		if indexPath.row >= currentEvent.count {
			return false
		}

		if currentEvent[indexPath.row].username == appDelegate.usernameOfTesSoMe {
			return true
		}
		return false
	}
	
	func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
		let cell = tableView.cellForRowAtIndexPath(indexPath) as ClassCell
		let event = currentEvent[indexPath.row]
		if event.username == appDelegate.usernameOfTesSoMe {
			let deleteAction = UITableViewRowAction(style: .Default, title: NSLocalizedString("Delete", comment: "Delete"))
				{ action, indexPath in
					let alertTitle = NSLocalizedString("Cancel Class", comment: "Alert confirmation title (delete class event)")
					let confirmationText = NSLocalizedString("Do you want to delete this class?", comment: "Alert confirmation text (delete class event)")
					let alertController = UIAlertController(title: alertTitle, message: "\(cell.dateLabel.text!)\n\n\(confirmationText)", preferredStyle: .Alert)
					
					let removeClassNotificationAction = UIAlertAction(title: NSLocalizedString("Delete", comment: "Delete"), style: .Destructive, handler:
						{ action in
							self.apiManager.removeClass(date: event.date, text: event.title, onSuccess:
								{ data in
									let okAlertController = UIAlertController(title: NSLocalizedString("Success", comment: "Success"), message: NSLocalizedString("Deleting Class Succeeded", comment: "Deleting Class Succeeded"), preferredStyle: .Alert)
									
									let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Cancel, handler:
										{ action in
											self.getClass()
										}
									)
									okAlertController.addAction(okAction)
									
									self.presentViewController(okAlertController, animated: true, completion: nil)
								}
								, onFailure:
								{ err in
									let errAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: err.localizedDescription, preferredStyle: .Alert)
									
									let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Cancel, handler: nil)
									errAlertController.addAction(okAction)
									
									self.presentViewController(errAlertController, animated: true, completion: nil)
								}
							)
							
						}
					)
					alertController.addAction(removeClassNotificationAction)
					
					let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
					alertController.addAction(cancelAction)
					
					self.presentViewController(alertController, animated: true, completion: nil)
			}
			deleteAction.backgroundColor = UIColor.redColor()
			return [deleteAction]
		}
		return nil
	}
	
	func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		
	}

	
	override func setEditing(editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		self.classTableView.allowsMultipleSelectionDuringEditing = editing
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
