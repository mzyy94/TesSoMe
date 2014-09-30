//
//  PostMainViewController.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/24.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class PostMainViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
	let app = UIApplication.sharedApplication()
	let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
	let ud = NSUserDefaults()

	var menu: REMenu!
	var messageType: TessoMessageType = .Unknown
	var preparedText = ""
	
    var fileURLtoPost: NSURL? = nil
	var topicid = 1
	
	@IBOutlet weak var postTitleBtn: UIButton!
	@IBOutlet weak var textView: UITextView!
	
	@IBAction func postTitleBtnPressed(sender: AnyObject) {
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
		
		self.textView.font = UIFont.systemFontOfSize(CGFloat(ud.floatForKey("fontSize") + 4.0))
		
		let topicMenuViewController = appDelegate.frostedViewController?.menuViewController as TopicMenuViewController
		topicid = topicMenuViewController.currentTopic
		
		self.providesPresentationContextTransitionStyle = true
		self.definesPresentationContext = true
		
		self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: Selector("closeView"))

		self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: Selector("sendPost"))
		
		showKeyboard()
	}
	
	func initMenu() {
		let selectMessageItem = REMenuItem(title: NSLocalizedString("Message", comment: "Message on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("Message")
			self.messageType = .Message
			self.showKeyboard()
		})
		let selectFileUploadItem = REMenuItem(title: NSLocalizedString("File upload", comment: "File upload on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			let oldMenuItems = self.menu.items
			func generateChoosePhotoFunc(own: PostMainViewController, #doAfter: () -> Void)(type: UIImagePickerControllerSourceType)(item: REMenuItem!) {
                let picker = UIImagePickerController()
                picker.delegate = own
				picker.sourceType = type
				picker.mediaTypes = UIImagePickerController.availableMediaTypesForSourceType(type)!
				own.presentViewController(picker, animated: true, completion: nil)
				doAfter()
			}

			let choosePhoto = generateChoosePhotoFunc(self, doAfter: {self.menu.items = oldMenuItems})
			
			let takePhoto = REMenuItem(title: NSLocalizedString("Camera", comment: "Camera"), image: nil, highlightedImage: nil, action: choosePhoto(type: .Camera))
			
			let selectPhoto = REMenuItem(title: NSLocalizedString("Photo Library", comment: "Photo Library"), image: nil, highlightedImage: nil, action: choosePhoto(type: .PhotoLibrary))
			
			self.menu.items = [takePhoto, selectPhoto]
			self.menu.showFromNavigationController(self.navigationController)
			
		})
		let selectDrawingItem = REMenuItem(title: NSLocalizedString("Drawing", comment: "Drawing on navigation bar"), image: nil, highlightedImage: nil, action: {
			item in
			self.setTitleBtnText("Drawing")
			self.messageType = .Drawing
		})
		self.menu = REMenu(items: [selectMessageItem, selectFileUploadItem, selectDrawingItem])
		menu.liveBlur = true
		menu.liveBlurBackgroundStyle = REMenuLiveBackgroundStyle.Dark
		menu.separatorColor = UIColor(white: 0.0, alpha: 0.4)
		menu.borderColor = UIColor.clearColor()
		menu.textColor = UIColor(white: 1.0, alpha: 0.78)
	}
	
	func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
				let infoDic = NSDictionary(dictionary: info)
		let mediaType = infoDic[UIImagePickerControllerMediaType] as String
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
				println(err?.localizedDescription)
				if err == nil {
					fileURLtoPost = tmpDir.URLByAppendingPathComponent(fileName)
					fileManager.createFileAtPath(fileURLtoPost!.relativePath!, contents: fileToPost, attributes: nil)
					self.setTitleBtnText("File upload")
					self.messageType = .File
				}
			}
			picker.dismissViewControllerAnimated(true, completion: nil)

			let image = infoDic[UIImagePickerControllerOriginalImage] as UIImage
			self.resizeImageActionSheet(image, compilation: saveImageToTmp)
		} else {
            fileURLtoPost = NSURL(string: infoDic[UIImagePickerControllerMediaURL] as String)
			self.setTitleBtnText("File upload")
			self.messageType = .File
			picker.dismissViewControllerAnimated(true, completion: nil)
        }
	}
	
	func resizeImageActionSheet(image: UIImage, compilation:((UIImage) -> Void)) {
		let width = Int(image.size.width)
		let height = Int(image.size.height)
		
		var alertController = UIAlertController(title: NSLocalizedString("Resize image", comment: "Resize image on ActionSheet"), message: NSLocalizedString("You can reduce message size by scaling the image to one of the sizes below.", comment: "You can reduce message size by scaling the image to one of the sizes below."), preferredStyle: .ActionSheet)
		
		let actualSize = UIAlertAction(title: NSString(format: NSLocalizedString("Actual Size (%d x %d)", comment: "Actual Size"), width, height), style: .Default) {
			action in
			compilation(image)
		}
		alertController.addAction(actualSize)

		let largeSize = UIAlertAction(title: NSString(format: NSLocalizedString("Large Size (%d x %d)", comment: "Large Size"), width * 2 / 3, height * 2 / 3), style: .Default) {
			action in
			compilation(self.resizeImage(image, width: CGFloat(width * 2 / 3), height: CGFloat(height * 2 / 3)))
		}
		alertController.addAction(largeSize)
		
		let mediumSize = UIAlertAction(title: NSString(format: NSLocalizedString("Medium Size (%d x %d)", comment: "Medium Size"), width * 2 / 5, height * 2 / 5), style: .Default) {
			action in
			compilation(self.resizeImage(image, width: CGFloat(width * 2 / 5), height: CGFloat(height * 2 / 5)))
		}
		alertController.addAction(mediumSize)
		
		let smallSize = UIAlertAction(title: NSString(format: NSLocalizedString("Small Size (%d x %d)", comment: "Small Size"), width * 1 / 4, height * 1 / 4), style: .Default) {
			action in
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
		let text = self.textView.text
		
		func failureAction(err: NSError) {
			let notification = MPGNotification(title: NSLocalizedString("Post failed.", comment: "Post failed."), subtitle: err.localizedDescription, backgroundColor: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0), iconImage: UIImage(named: "warning_icon"))
			notification.duration = 5.0
			notification.animationType = .Drop
			notification.setButtonConfiguration(.OneButton, withButtonTitles: [NSLocalizedString("Edit", comment: "Edit")])
			notification.buttonHandler = {
				notification, buttonIndex in
				if buttonIndex == notification.firstButton.tag ||
					buttonIndex == notification.backgroundView.tag {
						self.app.openURL(NSURL(string: NSString(format: "tesso://post/?text=%@", text)))
				}
			}
			notification.show()
		}
		let onFailure = failureAction
		
		switch messageType {
		case .Message:
			closeView({
				apiManager.sendMessage(topicid: self.topicid, message: text, onSuccess: nil, onFailure: onFailure)
			})
		case .File:
			closeView({
				apiManager.uploadFile(fileURL: self.fileURLtoPost!, onSuccess: nil, onFailure: onFailure)(topicid: self.topicid)
			})
		case .Drawing:
			closeView({
				apiManager.sendMessage(topicid: self.topicid, message: text, onSuccess: nil, onFailure: onFailure)
			})
		default:
			NSLog("Unknown message type to post (value: %d)", messageType.toRaw())
		}
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue!, sender: AnyObject!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
