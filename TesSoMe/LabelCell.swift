//
//  LabelCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/03.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class LabelCell: UITableViewCell {

	var labeledUsername = ""
	
	@IBOutlet weak var userIconBtn: UIButton!
	@IBOutlet weak var labelLabel: UILabel!
	@IBAction func userIconBtnPressed() {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let userViewController = storyboard.instantiateViewControllerWithIdentifier("UserView") as UserViewController
		userViewController.username = labeledUsername
		
		let tableView = self.superview?.superview as UITableView
		let viewController = (tableView.dataSource as AnyObject!) as UIViewController
		viewController.navigationController?.pushViewController(userViewController, animated: true)
	}
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		// Round edge
		self.userIconBtn.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIconBtn.layer.borderWidth = 1.0
		self.userIconBtn.layer.cornerRadius = 4.0
		self.userIconBtn.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
