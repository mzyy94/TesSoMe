//
//  ColorPickerViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/09.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class ColorPickerViewController: UICollectionViewController {

	var size: CGFloat = 5.0
	var color: UIColor = UIColor.blackColor()
	
	var colors: [UIColor] = []
	
	var sizeSlider: UISlider! = nil
	
	func generateColors() {
		for white in 0..<32 {
			let color = UIColor(white: (32.0 - CGFloat(white)) / 32.0, alpha: 1.0)
			self.colors.append(color)
		}
		
		for r in 0..<6 {
			for g in 0..<6 {
				for b in 0..<6 {
					let color = UIColor(red: CGFloat(r) / 5.0, green: CGFloat(g) / 5.0, blue: CGFloat(b) / 5.0, alpha: 1.0)
					self.colors.append(color)
				}
			}
		}
		
		self.colors.removeLast()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		generateColors()
		self.collectionView?.reloadData()

		for i in 0..<colors.count {
			if colors[i] == color {
				self.collectionView?.scrollToItemAtIndexPath(NSIndexPath(forRow: i, inSection: 0), atScrollPosition: .Top, animated: false)
				break
			}
		}

		sizeSlider = UISlider()
		sizeSlider.minimumValue = 1.0
		sizeSlider.maximumValue = 30.0
		sizeSlider.value = Float(size)
		sizeSlider.tintColor = color
		sizeSlider.addTarget(self, action: Selector("changeSize:"), forControlEvents: .ValueChanged)
		self.navigationItem.titleView = UIView(frame: self.navigationController!.navigationBar.frame)
		
		sizeSlider.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		self.navigationItem.titleView?.addSubview(sizeSlider)

		let attributes: [NSLayoutAttribute] = [.Top, .Left, .Right, .Bottom]
		
		for attribute in attributes {
			let constraint = NSLayoutConstraint(item: sizeSlider, attribute: attribute, relatedBy: .Equal, toItem: self.navigationItem.titleView, attribute: attribute, multiplier: 1.0, constant: 0.0)
			self.navigationItem.titleView?.addConstraint(constraint)
		}
		
		let colorPreviewView = UIImageView(frame: CGRect(x: 0, y: 0, width: 64, height: 64))
		self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: colorPreviewView)
		drawPreviewImage()
		
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}
	
	func changeSize(sender: UISlider) {
		size = CGFloat(sender.value)
		drawPreviewImage()
	}
	
	func drawPreviewImage() {
		let imageView = self.navigationItem.rightBarButtonItem?.customView as UIImageView
		
		UIGraphicsBeginImageContext(imageView.bounds.size)
		let context = UIGraphicsGetCurrentContext()
		let circle = CGRect(x: (imageView.bounds.size.width - size) / 2, y: (imageView.bounds.size.height - size) / 2, width: size, height: size)
		
		CGContextSetLineWidth(context, 1.0)
		CGContextSetStrokeColorWithColor(context, UIColor.lightGrayColor().CGColor)
		CGContextSetFillColorWithColor(context, color.CGColor)
		
		CGContextStrokeEllipseInRect(context, circle)
		CGContextFillEllipseInRect(context, circle)
		imageView.image = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}

	override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return colors.count
	}
	
	
	override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let colorCell = collectionView.dequeueReusableCellWithReuseIdentifier("ColorCell", forIndexPath: indexPath) as UICollectionViewCell
		colorCell.backgroundColor = self.colors[indexPath.row]
		return colorCell
	}
	
	
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		color = colors[indexPath.row]
		sizeSlider.tintColor = color
		drawPreviewImage()
		return
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		
		let postDrawingViewController = self.parentViewController?.childViewControllers.first as PostDrawingViewController
		postDrawingViewController.color = self.color
		postDrawingViewController.size = self.size

	}
}
