//
//  PostDrawingViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/10/09.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class DrawingPath: NSObject {
	var path: UIBezierPath! = nil
	var color: UIColor! = nil
	init(path aPath: UIBezierPath, color aColor: UIColor) {
		self.path = aPath
		self.color = aColor
	}
}

class PostDrawingViewController: UIViewController {
	
	let imageSize = CGSize(width: 250, height: 85)
	let imageRect = CGRect(origin: CGPointZero, size: CGSize(width: 250, height: 85))
	
	var path:UIBezierPath! = nil
	var undoStack:[DrawingPath] = []
	var redoStack:[DrawingPath] = []
	var drawing = false
	var color = UIColor.blackColor()
	var size: CGFloat = 5.0
	var initialImage: UIImage! = nil

	@IBOutlet weak var drawingImage: UIImageView!
	@IBOutlet weak var undoBtn: UIBarButtonItem!
	@IBOutlet weak var redoBtn: UIBarButtonItem!
	
	@IBAction func undoBtnPressed(sender: UIBarButtonItem) {
		undo()
	}
	
	@IBAction func redoBtnPressed(sender: UIBarButtonItem) {
		redo()
	}
	
	@IBAction func toolBtnPressed(sender: UIBarButtonItem) {
		self.performSegueWithIdentifier("ShowColorPicker", sender: self)
	}
	
	func undo() {
		redoStack.append(undoStack.removeLast())
		
		drawingImage.image = initialImage
		
		for undo in undoStack {
			drawLine(path: undo.path, color: undo.color)
		}
		self.undoBtn.enabled = !undoStack.isEmpty
		self.redoBtn.enabled = true
	}
	
	func redo() {
		let redo = redoStack.removeLast()
		undoStack.append(redo)
		
		drawLine(path: redo.path, color: redo.color)
		
		self.undoBtn.enabled = true
		self.redoBtn.enabled = !redoStack.isEmpty
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		UIGraphicsBeginImageContext(imageSize)
		let rect = imageRect
		
		if initialImage != nil {
			initialImage.drawInRect(rect)
		} else {
			let context = UIGraphicsGetCurrentContext()
			CGContextSetFillColorWithColor(context, UIColor.whiteColor().CGColor)
			CGContextFillRect(context, rect)
		}
		
		initialImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		drawingImage.image = initialImage
		drawingImage.contentMode = UIViewContentMode.ScaleToFill
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		
		if undoStack.count > 16 {
			UIGraphicsBeginImageContext(imageSize)
			initialImage.drawInRect(imageRect)
			
			for _ in 0..<(undoStack.count - 16) {
				let undo = undoStack.removeAtIndex(0)
				undo.color.setStroke()
				undo.path.stroke()
			}
			
			initialImage = UIGraphicsGetImageFromCurrentImageContext()
			UIGraphicsEndImageContext()
		}
	}
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
		self.parentViewController?.presentingViewController?.navigationController?.setNavigationBarHidden(true, animated: true)
	}
	
	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		self.parentViewController?.presentingViewController?.navigationController?.setNavigationBarHidden(false, animated: true)
	}
	
	func drawLine(path aPath: UIBezierPath, color aColor: UIColor) {
		UIGraphicsBeginImageContext(imageSize)
		
		self.drawingImage.image!.drawInRect(imageRect)
		aColor.setStroke()
		aPath.stroke()
		self.drawingImage.image = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
	}

	override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
		let viewPoint = touches.anyObject()!.locationInView(self.view)

		if !CGRectContainsPoint(self.drawingImage.frame, viewPoint) {
			drawing = false
			return
		}
		
		path = UIBezierPath()
		path.lineWidth = size
		path.lineCapStyle = kCGLineCapRound
		
		let currentPoint = touches.anyObject()!.locationInView(self.drawingImage)
		let scale: CGFloat = self.drawingImage.bounds.size.width / self.imageSize.width
		let scaledPoint = CGPoint(x: currentPoint.x / scale, y: currentPoint.y / scale)
		
		path.moveToPoint(scaledPoint)
		drawing = true
	}
	
	override func touchesMoved(touches: NSSet, withEvent event: UIEvent) {
		if (!drawing) {
			return
		}
		
		let currentPoint = touches.anyObject()!.locationInView(self.drawingImage)
		let scale: CGFloat = self.drawingImage.bounds.size.width / self.imageSize.width
		let scaledPoint = CGPoint(x: currentPoint.x / scale, y: currentPoint.y / scale)
		
		path.addLineToPoint(scaledPoint)
		drawLine(path: path, color: color)
	}
	
	override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
		if (!drawing) {
			return
		}
		let currentPoint = touches.anyObject()!.locationInView(self.drawingImage)
		let scale: CGFloat = self.drawingImage.bounds.size.width / self.imageSize.width
		let scaledPoint = CGPoint(x: currentPoint.x / scale, y: currentPoint.y / scale)
		
		path.addLineToPoint(scaledPoint)
		drawLine(path: path, color: color)
		
		undoStack.append(DrawingPath(path: path, color: color))
		
		if undoStack.count > 32 {
			let undo = undoStack.removeAtIndex(0)
			
			UIGraphicsBeginImageContext(imageSize)
			
			initialImage.drawInRect(imageRect)
			undo.color.setStroke()
			undo.path.stroke()
			
			initialImage = UIGraphicsGetImageFromCurrentImageContext()
			
			UIGraphicsEndImageContext()
		}
		
		undo()
		redo()
		
		undoBtn.enabled = true
		redoStack.removeAll(keepCapacity: false)
		redoBtn.enabled = false
		drawing = false
		path = nil
		
		let postMainViewController = self.presentingViewController as PostMainViewController
		postMainViewController.drawingImage = self.drawingImage.image
	}
	
	override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
		self.touchesEnded(touches, withEvent: event)
	}
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		if segue.identifier == "ShowColorPicker" {
			let colorPickerViewController = segue.destinationViewController as ColorPickerViewController
			colorPickerViewController.color = self.color
			colorPickerViewController.size = self.size
		}
	}

}
