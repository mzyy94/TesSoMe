//
//  PhotoCaptionView.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/30.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class PhotoCaptionView: UIVisualEffectView {

	@IBOutlet weak var userIcon: UIImageView!
	@IBOutlet weak var statusIdLabel: UILabel!
	@IBOutlet weak var nicknameLabel: UILabel!
	@IBOutlet weak var usernameLabel: UILabel!
	@IBOutlet weak var timeStampLabel: UILabel!
	@IBOutlet weak var messageTextView: UITextView!
	@IBOutlet weak var viaTesSoMeBadge: UIImageView!
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect)
    {
        // Drawing code
    }
    */
	
	override func awakeFromNib() {
		super.awakeFromNib()
		// Initialization code
		
		// Round edge
		self.userIcon.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.userIcon.layer.borderWidth = 1.0
		self.userIcon.layer.cornerRadius = 4.0
		self.userIcon.clipsToBounds = true
		
		self.viaTesSoMeBadge.layer.borderColor = UIColor(white: 0.0, alpha: 0.3).CGColor
		self.viaTesSoMeBadge.layer.borderWidth = 1.0
		self.viaTesSoMeBadge.layer.cornerRadius = self.viaTesSoMeBadge.frame.height / 2
		self.viaTesSoMeBadge.clipsToBounds = true
		
		self.messageTextView.textContainer.lineFragmentPadding = 0
		self.messageTextView.contentInset.top = -8.0
	}
	


}
