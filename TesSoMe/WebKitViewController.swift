//
//  WebKitViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/02.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import WebKit

class WebKitViewController: UIViewController, WKNavigationDelegate {
	let app = UIApplication.sharedApplication()
	let ud = NSUserDefaults()
	
	var webView: WKWebView! = nil
	var url: NSURL! = nil
	
	override func loadView() {
		super.loadView()
		
		self.webView = WKWebView()
		self.webView.configuration.preferences.minimumFontSize = CGFloat(ud.floatForKey("fontSize"))
		self.webView.navigationDelegate = self
		self.webView.allowsBackForwardNavigationGestures = true
		
		self.webView.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		for constraintAttribute: NSLayoutAttribute in [.Width, .Height] {
			self.view.addConstraint(NSLayoutConstraint(item: self.webView, attribute: constraintAttribute, relatedBy: .Equal, toItem: self.view, attribute: constraintAttribute, multiplier: 1.0, constant: 0))
		}
		
		self.view.insertSubview(self.webView, atIndex: 0)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
		self.webView.addObserver(self, forKeyPath: "title", options: .New, context: nil)
		self.webView.addObserver(self, forKeyPath: "loading", options: .New, context: nil)
		
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("showShareAction"))
		
		let req = NSURLRequest(URL: url)
		self.webView.loadRequest(req)
	}
	
	override func viewWillDisappear(animated: Bool) {
		self.navigationController?.setSGProgressPercentage(0.0, andTintColor: UIColor.globalTintColor())
		app.networkActivityIndicatorVisible = false
	}
	
	func showShareAction() {
		var alertController = UIAlertController(title: NSLocalizedString("Share", comment: "Share on ActionSheet"), message: nil, preferredStyle: .ActionSheet)
		
		let openWithSafari = UIAlertAction(title: NSLocalizedString("Open with Safari", comment: "Open with Safari"), style: .Default, handler:
			{ action in
				self.app.openURL(self.webView.URL!)
				return // To avoid error
		})
		alertController.addAction(openWithSafari)
		
		let postThisSite = UIAlertAction(title: NSLocalizedString("Post this site", comment: "Post this site"), style: .Default, handler:
			{ action in
				let title = self.webView.title as String!
				let url = self.webView.URL!.absoluteString as String!
				let text = "\(title) \n\(url) ".stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
				self.app.openURL(NSURL(string: "tesso://post/?text=\(text!)")!)
		})
		alertController.addAction(postThisSite)
		
		let cancel = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .Cancel, handler: nil)
		alertController.addAction(cancel)
		
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	deinit {
		self.webView.removeObserver(self, forKeyPath: "estimatedProgress")
		self.webView.removeObserver(self, forKeyPath: "title")
		self.webView.removeObserver(self, forKeyPath: "loading")
	}

	override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
		switch keyPath {
		case "estimatedProgress":
			self.navigationController?.setSGProgressPercentage(Float(self.webView.estimatedProgress * 100.0), andTintColor: UIColor.globalTintColor())
		case "title":
			self.title = self.webView.title
		case "loading":
			app.networkActivityIndicatorVisible = self.webView.loading
		default:
			NSLog("Unknown observe keyPath = %@", keyPath)
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	

}
