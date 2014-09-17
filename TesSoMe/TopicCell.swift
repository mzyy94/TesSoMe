//
//  TopicCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TopicCell: UITableViewCell {

	@IBOutlet weak var userIcon: UIImageView!
	@IBOutlet weak var topicNumLabel: UILabel!
	@IBOutlet weak var topicTitleLabel: UILabel!
	@IBOutlet weak var latestMessageLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		self.userIcon.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIcon.layer.borderWidth = 1.0
		self.userIcon.layer.cornerRadius = 32
		self.userIcon.clipsToBounds = true
		self.backgroundColor = UIColor.clearColor()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
