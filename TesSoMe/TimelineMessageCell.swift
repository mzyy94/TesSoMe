//
//  TimelineMessageCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TimelineMessageCell: UITableViewCell {

	@IBOutlet weak var userIconBtn: UIButton!
	@IBOutlet weak var statusIdLabel: UILabel!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var timeStampLabel: UILabel!
	@IBOutlet weak var viaTesSoMeBadge: UIImageView!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
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
