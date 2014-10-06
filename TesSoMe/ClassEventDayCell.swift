//
//  ClassEventDayCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/06.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit


class ClassEvent: NSObject {
	var date: NSDate! = nil
	var dateComponents: NSDateComponents! = nil
	var title: String! = nil
	var username: String! = nil
	init(data: NSDictionary) {
		super.init()
		
		self.date = NSDate(timeIntervalSince1970: NSTimeInterval((data["unixtime"] as String).toInt()!))
		
		let timeZone = NSTimeZone.systemTimeZone()
		let calendar = NSCalendar.currentCalendar()
		self.dateComponents = calendar.componentsInTimeZone(timeZone, fromDate: date)
		
		self.title = data["data"] as String
		self.username = data["username"] as String
	}
}

class ClassEventDayCell: RDVCalendarDayCell {

	var notificationView: UIView! = nil
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override init(frame: CGRect) {
		super.init(frame: frame)
	}
	
	override init(reuseIdentifier: String!) {
		super.init(reuseIdentifier: reuseIdentifier)
		notificationView = UIView()
		notificationView.backgroundColor = UIColor.globalTintColor(alpha: 0.8)
		notificationView.hidden = true
		self.contentView.addSubview(notificationView)
		
		
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
		let viewSize = self.contentView.frame.size
		let badgeSize: CGFloat = 6.0
		self.notificationView.frame = CGRectMake((viewSize.width - badgeSize) / 2, viewSize.height - 8, badgeSize, badgeSize)
		self.notificationView.layer.cornerRadius = badgeSize / 2
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		self.notificationView.hidden = true
	}

}
