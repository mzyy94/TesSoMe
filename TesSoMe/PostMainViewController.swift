//
//  PostMainViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/24.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import AVFoundation

class PostMainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDelegate {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()

	var menu: REMenu! = nil
	var messageType: TessoMessageType = .Unknown
	var preparedText = ""
	
	var fileURLtoPost: NSURL? = nil
	var topicid: Int! = nil
	var drawingImage: UIImage! = nil
	
	@IBOutlet weak var postTitleBtn: UIButton!
	@IBOutlet weak var textView: UITextView!
	
	@IBAction func postTitleBtnPressed() {
		if menu.isOpen {
			menu.closeWithCompletion({
				self.showKeyboard()
			})
		} else {
			menu.showFromNavigationController(self.navigationController)
			closeKeyboard()
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		initMenu()
		
		self.textView.text = preparedText
		
		setTitleBtnText("Message")
		messageType = .Message
		
		if topicid == nil {
			topicid = 1
		}
		
		self.textView.font = UIFont.systemFontOfSize(CGFloat(ud.floatForKey("fontSize") + 4.0))
		
		self.providesPresentationContextTransitionStyle = true
		self.definesPresentationContext = true
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("closeView"))

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("sendPost"))
		
		showKeyboard()
	}
	
	func initMenu() {
		let selectMessageItem = REMenuItem(title: NSLocalizedString("Message", comment: "Message on navigation bar"), image: nil, highlightedImage: nil, action:
			{ item in
				self.setTitleBtnText("Message")
				self.messageType = .Message
				self.showKeyboard()
			}
		)
		let selectFileUploadItem = REMenuItem(title: NSLocalizedString("File upload", comment: "File upload on navigation bar"), image: nil, highlightedImage: nil, action:
			{ item in
				let oldMenuItems = self.menu.items
				func generateChoosePhotoFunc(own: PostMainViewController)(type: UIImagePickerControllerSourceType)(item: REMenuItem!) {
					let picker = UIImagePickerController()
					picker.delegate = own
					picker.sourceType = type
					picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(type)!
					picker.videoQuality = .TypeIFrame1280x720
					own.presentViewController(picker, animated: true, completion: nil)
				}
				
				let choosePhoto = generateChoosePhotoFunc(self)
				
				let takePhoto = REMenuItem(title: NSLocalizedString("Camera", comment: "Camera"), image: nil, highlightedImage: nil, action: choosePhoto(type: .Camera))
				
				let selectPhoto = REMenuItem(title: NSLocalizedString("Photo Library", comment: "Photo Library"), image: nil, highlightedImage: nil, action: choosePhoto(type: .PhotoLibrary))
				
				self.menu.items = [takePhoto, selectPhoto]
				self.menu.showFromNavigationController(self.navigationController)
				self.menu.items = oldMenuItems
			}
		)
		let selectDrawingItem = REMenuItem(title: NSLocalizedString("Drawing", comment: "Drawing on navigation bar"), image: nil, highlightedImage: nil, action:
			{ item in
				let oldMenuItems = self.menu.items
				func generateChoosePhotoFunc(own: PostMainViewController)(type: UIImagePickerControllerSourceType)(item: REMenuItem!) {
					let picker = UIImagePickerController()
					picker.delegate = own
					picker.sourceType = type
					picker.mediaTypes = ["public.image"]
					own.presentViewController(picker, animated: true, completion: nil)
				}
				
				let choosePhoto = generateChoosePhotoFunc(self)
				
				let takePhoto = REMenuItem(title: NSLocalizedString("Camera", comment: "Camera"), image: nil, highlightedImage: nil, action: choosePhoto(type: .Camera))
				
				let selectPhoto = REMenuItem(title: NSLocalizedString("Photo Library", comment: "Photo Library"), image: nil, highlightedImage: nil, action: choosePhoto(type: .PhotoLibrary))
				
				let whitePaper = REMenuItem(title: NSLocalizedString("White Paper", comment: "White Paper"), image: nil, highlightedImage: nil, action:
					{ item in
						self.showDrawingView()
					}
				)
				
				self.menu.items = [takePhoto, selectPhoto, whitePaper]
				self.menu.showFromNavigationController(self.navigationController)
				self.menu.items = oldMenuItems
			}
		)
		self.menu = REMenu(items: [selectMessageItem, selectFileUploadItem, selectDrawingItem])
		self.menu.liveBlur = true
		self.menu.liveBlurBackgroundStyle = .Dark
		self.menu.separatorColor = UIColor(white: 0.0, alpha: 0.4)
		self.menu.borderColor = UIColor.clearColor()
		self.menu.textColor = UIColor(white: 1.0, alpha: 0.78)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
		let infoDic = NSDictionary(dictionary: info)
		let mediaType = infoDic[UIImagePickerControllerMediaType] as String
		
		if picker.mediaTypes.count == 1 { // Drawing
			let image = infoDic[UIImagePickerControllerOriginalImage] as UIImage
			if picker.sourceType == .Camera {
				UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
			}
			
			let imageCropViewController = RSKImageCropViewController(image: image, cropMode: RSKImageCropMode.Custom, cropSize: CGSize(width: 250, height: 85))
			imageCropViewController.delegate = self
			picker.pushViewController(imageCropViewController, animated: true)
			return
		}
		
		if mediaType == "public.image" {
			func saveImageToTmp(image: UIImage) {
				let fileName = "Image.jpg"
				var tmpDir = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
				let fileToPost = UIImageJPEGRepresentation(image, 0.8)
				let fileManager = NSFileManager.defaultManager()
				let now = NSDate()
				var err: NSError? = nil
				tmpDir = tmpDir.URLByAppendingPathComponent("\(now.timeIntervalSince1970)")
				fileManager.createDirectoryAtURL(tmpDir, withIntermediateDirectories: true, attributes: nil, error: &err)
				if err == nil {
					fileURLtoPost = tmpDir.URLByAppendingPathComponent(fileName)
					fileManager.createFileAtPath(fileURLtoPost!.relativePath!, contents: fileToPost, attributes: nil)
					self.setTitleBtnText("File upload")
					self.messageType = .File
					self.addPreviewImage(image)
					self.addRenameFileMenu()
				}
			}
			picker.dismissViewControllerAnimated(true, completion: nil)

			let image = infoDic[UIImagePickerControllerOriginalImage] as UIImage
			if picker.sourceType == .Camera {
				UIImageWriteToSavedPhotosAlbum(image, self, nil, nil)
			}
			self.resizeImageActionSheet(image, compilation: saveImageToTmp)
		} else {
			fileURLtoPost = infoDic[UIImagePickerControllerMediaURL] as? NSURL
			self.setTitleBtnText("File upload")
			self.messageType = .File
			if picker.sourceType == .Camera && mediaType == "public.movie" {
				UISaveVideoAtPathToSavedPhotosAlbum(fileURLtoPost?.path, self, nil, nil)
			}
			self.addPreviewImage(makeThumbNail(fileURLtoPost!))
			self.addRenameFileMenu()
			picker.dismissViewControllerAnimated(true, completion: nil)
		}
	}
	
	func showDrawingView() {
		self.setTitleBtnText("Drawing")
		self.messageType = .Drawing
		
		let addComment = REMenuItem(title: NSLocalizedString("Add Comment", comment: "Add Comment"), image: nil, highlightedImage: nil, action:
			{ item in
				let alertController = UIAlertController(title: NSLocalizedString("Add Comment", comment: "Add Comment on AlertView"), message: NSLocalizedString("Please type comments of drawing.", comment: "Please type comments of drawing."), preferredStyle: .Alert)
				let addCommentAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default) {
					action in
					
					let textField = alertController.textFields?.first as UITextField
					self.textView.text = textField.text
					
					}
				alertController.addAction(addCommentAction)
				
				let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel, handler: nil)
				alertController.addAction(cancelAction)
				
				alertController.addTextFieldWithConfigurationHandler(
					{ textField in
						textField.text = self.textView.text
					}
				)
				
				self.presentViewController(alertController, animated: true, completion: nil)

		})
		
		self.menu.items = [addComment]
		
		self.performSegueWithIdentifier("ShowDrawingView", sender: self)
		self.navigationItem.leftBarButtonItem?.action = Selector("closeViewAll")
	}
	
	func imageCropViewController(controller: RSKImageCropViewController!, didCropImage croppedImage: UIImage!) {
		drawingImage = croppedImage
		controller.dismissViewControllerAnimated(true, completion: nil)
		showDrawingView()
	}
	
	func imageCropViewControllerDidCancelCrop(controller: RSKImageCropViewController!) {
		controller.dismissViewControllerAnimated(true, completion: nil)
	}
	
	var renameAction: UIAlertAction! = nil
	
	func addRenameFileMenu() {
		let renameFile = REMenuItem(title: NSLocalizedString("Rename file ", comment: "Rename file"), image: nil, highlightedImage: nil, action:
			{ item in
				let alertController = UIAlertController(title: NSLocalizedString("Rename File", comment: "Rename File on AlertView"), message: NSLocalizedString("Please type new file name.", comment: "Please type new file name."), preferredStyle: .Alert)
				self.renameAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default) {
					action in
					
					let textField = alertController.textFields?.first as UITextField
					let filename = textField.text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
					
					//let originalFileBaseURL = self.fileURLtoPost!.baseURL  // ERROR
					let originalFileBaseURL = NSURL(string: self.fileURLtoPost!.absoluteString!.stringByDeletingLastPathComponent)
					let fileExtension = self.fileURLtoPost!.pathExtension
					let renamedFileURL = NSURL(string: "\(filename!).\(fileExtension)", relativeToURL: originalFileBaseURL)
					
					if renamedFileURL == self.fileURLtoPost {
						// Will not rename
						return
					}
					
					let fileManager = NSFileManager.defaultManager()
					var err: NSError? = nil
					fileManager.moveItemAtURL(self.fileURLtoPost!, toURL: renamedFileURL, error: &err)
					if err == nil {
						self.fileURLtoPost = renamedFileURL
					} else {
						let errorAlertController = UIAlertController(title: NSLocalizedString("Rename Failed", comment: "Rename Failed on AlertView"), message: err?.localizedDescription, preferredStyle: .Alert)
						let okAction = UIAlertAction(title: NSLocalizedString("OK", comment: "OK on AlertView"), style: .Default, handler: nil)
						errorAlertController.addAction(okAction)
						self.presentViewController(errorAlertController, animated: true, completion: nil)
					}
					NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alertController.textFields?.first)
				}
				self.renameAction.enabled = false
				alertController.addAction(self.renameAction)
				
				let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel on AlertView"), style: .Cancel) {
					action in
					NSNotificationCenter.defaultCenter().removeObserver(self, name: UITextFieldTextDidChangeNotification, object: alertController.textFields?.first)
				}
				alertController.addAction(cancelAction)
				alertController.addTextFieldWithConfigurationHandler(
					{ textField in
						let label = UILabel(frame: CGRectMake(0, 0, 100, 20))
						label.text = " .\(self.fileURLtoPost!.pathExtension)"
						label.font = textField.font
						label.sizeToFit()
						textField.rightView = label
						textField.rightViewMode = UITextFieldViewMode.Always
						textField.placeholder = self.fileURLtoPost?.lastPathComponent.stringByDeletingPathExtension.stringByRemovingPercentEncoding
						NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleTextFieldTextDidChangeNotification:"), name: UITextFieldTextDidChangeNotification, object: textField)
					}
				)
				
				self.presentViewController(alertController, animated: true, completion: nil)
				
				
		})
		self.menu.items = [renameFile]
	}
	
	func handleTextFieldTextDidChangeNotification(notification: NSNotification) {
		let textField = notification.object as UITextField
		let filename = textField.text
		if filename == nil ||
			filename.rangeOfString("^ *$", options: .RegularExpressionSearch) != nil ||
			filename.rangeOfString("[/\\\\]", options: .RegularExpressionSearch) != nil {
				renameAction.enabled = false
		} else {
			renameAction.enabled = true
		}
	}
	
	func makeThumbNail(fileURL: NSURL) -> UIImage! {
		let asset = AVURLAsset(URL: fileURL, options: nil)
		if asset.tracksWithMediaCharacteristic(AVMediaTypeVideo) != nil {
			let imageGenerator = AVAssetImageGenerator(asset: asset)
			let duration = CMTimeGetSeconds(asset.duration)
			let startPoint = CMTimeMakeWithSeconds(duration / 8, 600)
			var err: NSError? = nil
			let thumbnailCGImage = imageGenerator.copyCGImageAtTime(startPoint, actualTime: nil, error: &err)
			if thumbnailCGImage != nil {
				return UIImage(CGImage: thumbnailCGImage)
			}
		}
		return nil
	}
	
	func addPreviewImage(image: UIImage!) {
		self.textView.editable = false

		if image == nil {
			return
		}
		let previewImage = UIImageView()
		previewImage.setTranslatesAutoresizingMaskIntoConstraints(false)
		
		self.view.addSubview(previewImage)
		
		let constrains: [NSLayoutAttribute: CGFloat] = [.Top: 72.0, .Left: 8.0, .Right: -8.0, .Bottom: -8.0]
		
		for (layoutAttribute, value) in constrains {
			let constraint = NSLayoutConstraint(item: previewImage, attribute: layoutAttribute, relatedBy: .Equal, toItem: self.view, attribute: layoutAttribute, multiplier: 1.0, constant: value)
			self.view.addConstraint(constraint)
		}
		previewImage.autoresizingMask = .FlexibleHeight
		previewImage.clipsToBounds = true
		previewImage.contentMode = .ScaleAspectFit
		previewImage.image = image
	}
	
	func resizeImageActionSheet(image: UIImage, compilation:((UIImage) -> Void)) {
		let width = Int(image.size.width)
		let height = Int(image.size.height)
		
		var alertController = UIAlertController(title: NSLocalizedString("Resize image", comment: "Resize image on ActionSheet"), message: NSLocalizedString("You can reduce message size by scaling the image to one of the sizes below.", comment: "You can reduce message size by scaling the image to one of the sizes below."), preferredStyle: .ActionSheet)
		
		let actualSize = UIAlertAction(title: NSString(format: NSLocalizedString("Actual Size (%d x %d)", comment: "Actual Size"), width, height), style: .Default)
			{ action in
				compilation(image)
		}
		alertController.addAction(actualSize)

		let largeSize = UIAlertAction(title: NSString(format: NSLocalizedString("Large Size (%d x %d)", comment: "Large Size"), width * 2 / 3, height * 2 / 3), style: .Default)
			{ action in
				compilation(self.resizeImage(image, width: CGFloat(width * 2 / 3), height: CGFloat(height * 2 / 3)))
		}
		alertController.addAction(largeSize)
		
		let mediumSize = UIAlertAction(title: NSString(format: NSLocalizedString("Medium Size (%d x %d)", comment: "Medium Size"), width * 2 / 5, height * 2 / 5), style: .Default)
			{ action in
				compilation(self.resizeImage(image, width: CGFloat(width * 2 / 5), height: CGFloat(height * 2 / 5)))
		}
		alertController.addAction(mediumSize)
		
		let smallSize = UIAlertAction(title: NSString(format: NSLocalizedString("Small Size (%d x %d)", comment: "Small Size"), width * 1 / 4, height * 1 / 4), style: .Default)
			{ action in
				compilation(self.resizeImage(image, width: CGFloat(width * 1 / 4), height: CGFloat(height * 1 / 4)))
		}
		alertController.addAction(smallSize)
		
		self.presentViewController(alertController, animated: true, completion: nil)
	}
	
	func resizeImage(image: UIImage, width: CGFloat, height: CGFloat) -> UIImage {
		let size = CGSizeMake(width, height)
		UIGraphicsBeginImageContext(size)
		image.drawInRect(CGRectMake(0, 0, size.width, size.height))
		let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return resizedImage
	}
	
	func setTitleBtnText(text: String) {
		self.postTitleBtn.backgroundColor = UIColor.globalTintColor()
		self.postTitleBtn.layer.cornerRadius = 14.0
		self.postTitleBtn.clipsToBounds = true
		let titleText = NSMutableAttributedString(string: text, attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(16.0), NSForegroundColorAttributeName: UIColor.whiteColor()])
		let dropDownMenuText = NSAttributedString(string: "  ▼", attributes: [NSFontAttributeName: UIFont.boldSystemFontOfSize(10.0), NSForegroundColorAttributeName: UIColor.whiteColor()])
		
		titleText.appendAttributedString(dropDownMenuText)
		self.postTitleBtn.setAttributedTitle(titleText, forState: .Normal)
	}
	
	func closeView() {
		closeKeyboard()
		self.dismissViewControllerAnimated(true, completion: nil)
	}

	func closeViewAll() {
		closeKeyboard()
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
	}
	
	func closeViewAll(completion: (() -> Void)! = nil) {
		closeKeyboard()
		self.presentingViewController?.dismissViewControllerAnimated(true, completion: completion)
	}
	
	func closeView(completion: (() -> Void)! = nil) {
		closeKeyboard()
		self.dismissViewControllerAnimated(true, completion: completion)
	}
	
	func showKeyboard() {
		self.textView.becomeFirstResponder()
	}
	
	func closeKeyboard() {
		self.textView.endEditing(true)
	}

	func sendPost() {
		let apiManager = TessoApiManager()
		var text = TesSoMeData.convertKML(self.textView.text)
		
		if ud.boolForKey("viaSignature") && text.utf16Count > 0 && text.utf16Count < 1018 {
			text += "     "
		}
		
		func failureAction(err: NSError) {
			let notification = MPGNotification(title: NSLocalizedString("Post failed.", comment: "Post failed."), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
			notification.duration = 5.0
			notification.animationType = .Drop
			notification.setButtonConfiguration(.OneButton, withButtonTitles: [NSLocalizedString("Edit", comment: "Edit")])
			notification.swipeToDismissEnabled = false
			notification.buttonHandler = {
				notification, buttonIndex in
				if buttonIndex == notification.firstButton.tag {
					self.app.openURL(NSURL(string: "tesso://post/?topic=\(self.topicid)&text=\(text.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!)"))
				}
			}
			notification.show()
		}
		
		func successAction(data: NSDictionary) {
			let rootTabBarController = appDelegate.frostedViewController?.contentViewController as RootViewController
			let timelineViewController = rootTabBarController.viewControllers?.first?.viewControllers?.first as TimelineViewController
			timelineViewController.updateTimelineFetchTimer?.fire()
		}
		
		let onFailure = failureAction
		let onSuccess = successAction
		
		switch messageType {
		case .Message:
			closeView({
				apiManager.sendMessage(topicid: self.topicid, message: text, onSuccess: onSuccess, onFailure: onFailure)
			})
		case .File:
			closeView({
				apiManager.uploadFile(fileURL: self.fileURLtoPost!, onSuccess: onSuccess, onFailure: onFailure)(topicid: self.topicid)
			})
		case .Drawing:
			closeViewAll({
				apiManager.sendDrawing(topicid: self.topicid, message: text, drawing: self.drawingImage, onSuccess: onSuccess, onFailure: onFailure)
			})
		default:
			NSLog("Unknown message type to post (value: %d)", messageType.toRaw())
		}
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
		if segue.identifier == "ShowDrawingView" {
			let postDrawingViewController = segue.destinationViewController.childViewControllers.first as PostDrawingViewController
			postDrawingViewController.initialImage = drawingImage
		}
	}
	
}
