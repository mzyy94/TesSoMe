//
//  UIColorExtension.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/27.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import Foundation

extension UIColor {
	 class func globalTintColor() -> UIColor {
		return UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: 1.0)
	}
	
	 class func globalTintColor(#alpha: CGFloat) -> UIColor {
		return UIColor(red: 0.96470588235294119, green: 0.31764705882352939, blue: 0.058823529411764705, alpha: alpha)
	}
}