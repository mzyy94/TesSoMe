//
//  HTMLEntityConverter.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/17.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class HTMLEntityConverter: NSObject, NSXMLParserDelegate {
	var result = ""
	
	override init() {
		result = ""
	}
	
	func decodeXML(s:String) -> String {
		result = ""
		var xmlStr = NSString(format: "<d>%@</d>", s)
		var data = xmlStr.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
		var xmlParse = NSXMLParser(data: data)
		xmlParse.delegate = self
		xmlParse.parse()
		return result
	}
	
	func parser(parser: NSXMLParser!, foundCharacters string: String!) {
		result += string
	}
}
