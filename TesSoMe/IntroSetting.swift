//
//  IntroSetting.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/07.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class IntroSetting: UIView {
	
	let ud = NSUserDefaults()

	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UITextView!
	@IBOutlet weak var enableBtn: UIButton!
	@IBOutlet weak var disableBtn: UIButton!
	
	var userDefaultsKey = ""
	var enableAction: (() -> Void)! = nil
	
	@IBAction func enableBtnPressed() {
		enableBtn.backgroundColor = UIColor.whiteColor()
		enableBtn.setTitleColor(UIColor.globalTintColor(), forState: .Normal)
		disableBtn.enabled = false
		
		ud.setBool(true, forKey: userDefaultsKey)
		
		enableAction?()
		
		let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("goNextPage"), userInfo: nil, repeats: false)
	}
	
	func goNextPage() {
		let introView = self.superview?.superview?.superview as EAIntroView
		introView.setCurrentPageIndex(introView.currentPageIndex + 1, animated: true)
	}
	
	@IBAction func disableBtnPressed() {
		disableBtn.backgroundColor = UIColor.whiteColor()
		disableBtn.setTitleColor(UIColor.globalTintColor(), forState: .Normal)
		enableBtn.enabled = false

		ud.setBool(false, forKey: userDefaultsKey)
		
		let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: Selector("goNextPage"), userInfo: nil, repeats: false)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()

		self.enableBtn.layer.borderColor = UIColor.whiteColor().CGColor
		self.enableBtn.layer.borderWidth = 1.0
		self.enableBtn.layer.cornerRadius = 4.0
		self.enableBtn.clipsToBounds = true
		
		self.disableBtn.layer.borderColor = UIColor.whiteColor().CGColor
		self.disableBtn.layer.borderWidth = 1.0
		self.disableBtn.layer.cornerRadius = 4.0
		self.disableBtn.clipsToBounds = true
	}
	
}
