//
//  ClassCell.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/06.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ClassCell: UITableViewCell {

	@IBOutlet weak var userIcon: UIImageView!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var dateLabel: UILabel!
	
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
		
		self.userIcon.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIcon.layer.borderWidth = 1.0
		self.userIcon.layer.cornerRadius = 4.0
		self.userIcon.clipsToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
