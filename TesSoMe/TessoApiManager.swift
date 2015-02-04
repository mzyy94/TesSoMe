//
//  TessoApiManager.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/13.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

enum TesSoMeSearchType: Int {
	case All = -1
	case Message = 0
	case Drawing = 1
	case File = 2
}

class TessoApiManager: NSObject {
#if TARGET_IS_SHARE_EXTENSION
#else
	let app = UIApplication.sharedApplication()
#endif
	
	let apiEndPoint = "https://tesso.pw/sns/api"
	
	enum TesSoMeGetMode: Int {
		case Test = 0, Timeline, Topic, Class, Profile, SearchResult
	}
	
	enum TesSoMeSendMode: Int {
		case Message = 0, Drawing, FilePost, FileUpload, EditClass, UpdateProfile, AddTitle
	}
	
	var sessionConfig: NSURLSessionConfiguration! = nil
	
	override init() {
		self.sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
		self.sessionConfig.HTTPShouldSetCookies = true
		self.sessionConfig.sharedContainerIdentifier = "group.com.mzyy94.TesSoMe"
	}
	
	func signIn(#username: String, password: String, onSuccess: (() -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
		req.responseSerializer = AFHTTPResponseSerializer()
		req.POST("https://tesso.pw/users/sign_in", parameters: ["data[User][username]": username, "data[User][password]": password], success:
			{ res, data in
				if res.response!.URL == NSURL(string: "https://tesso.pw/sns") {
					onSuccess?()
				} else {
					let errorDetails = NSDictionary(objects: [NSLocalizedString("Your username or password was incorrect.", comment: "Your username or password was incorrect.")], forKeys: [NSLocalizedDescriptionKey], count: 1)
					let err = NSError(domain: "Sign in", code: 401, userInfo: errorDetails)
					onFailure?(err)
				}
			}
			, failure:
			{ res, err in
				false // to avoid error
				onFailure?(err)
		})
	}
	
	func signOut(onSuccess: (() -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		var url = NSURL(string: "https://tesso.pw/users/sign_out")!
		var req = NSMutableURLRequest(URL: url)
		NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue(), completionHandler:
			{ res, data, err in
				if err != nil {
					onFailure?(err)
				} else {
					onSuccess?()
				}
		})
	}
	
	func checkResponce(data: AnyObject!, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		let object = data as NSDictionary
		
#if TARGET_IS_SHARE_EXTENSION
#else
		app.networkActivityIndicatorVisible = false
#endif

		if object["status"] as NSString == "success" {
			onSuccess?(object)
		} else {
			let errMsg = ((object["data"] as NSArray)[0] as NSDictionary)["data"] as String
//			let errCode = (((object["data"] as NSArray)[0] as NSDictionary)["id"] as Int) // MEMO: SERVER SIDE BUG
			let errCode = 0
			let errorDetails = NSDictionary(objects: [errMsg], forKeys: [NSLocalizedDescriptionKey], count: 1)
			let err = NSError(domain: "API", code: errCode, userInfo: errorDetails)
			onFailure?(err)
		}
	}
	
	func getData(#mode: TesSoMeGetMode, topicid: Int? = nil, maxid: Int? = nil, sinceid: Int? = nil, tag: String? = nil, username: String? = nil, type: Int? = nil, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
		req.responseSerializer.acceptableContentTypes = NSSet(object: "text/html")
		
#if TARGET_IS_SHARE_EXTENSION
#else
		app.networkActivityIndicatorVisible = true
#endif

		var param = ["mode": mode.rawValue as AnyObject]
		if topicid != nil {
			param.updateValue(topicid!, forKey: "topicid")
		}
		if maxid != nil {
			param.updateValue(maxid!, forKey: "maxid")
		}
		if sinceid != nil {
			param.updateValue(sinceid!, forKey: "sinceid")
		}
		if tag != nil {
			param.updateValue(tag!, forKey: "tag")
		}
		if username != nil {
			param.updateValue(username!, forKey: "username")
		}
		if type != nil {
			param.updateValue(type!, forKey: "type")
		}
		req.GET("\(apiEndPoint)/get", parameters: param, success:
			{ res, data in
				self.checkResponce(data, onSuccess: onSuccess, onFailure: onFailure)
			}
			, failure:
			{ res, err in
#if TARGET_IS_SHARE_EXTENSION
#else
					self.app.networkActivityIndicatorVisible = false
#endif
				onFailure?(err)
		})
	}

	func sendData(#mode: TesSoMeSendMode, target: String? = nil, text: String? = nil, data: String? = nil, fileURL: NSURL? = nil, onProgress: ((session: NSURLSession!, task: NSURLSessionTask!, bytesSent:Int64, totalBytesSent:Int64, totalBytesExpectedToSend: Int64) -> Void)! = nil, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
		req.responseSerializer.acceptableContentTypes = NSSet(object: "text/html")

		var param = ["mode": mode.rawValue as AnyObject]
		if target != nil {
			param.updateValue(target!, forKey: "target")
		}
		if text != nil {
			param.updateValue(text!, forKey: "text")
		}
		if data != nil {
			param.updateValue(data!, forKey: "data")
		}
		
		
		if fileURL != nil {
			let data = NSData(contentsOfURL: fileURL!)
			let fileName = fileURL?.lastPathComponent?.stringByRemovingPercentEncoding
			let mimeType = getMimeType(fromURL: fileURL!)
			let task = req.POST("\(apiEndPoint)/send", parameters: param, constructingBodyWithBlock:
				{ formData in
					formData.appendPartWithFileData(data, name: "file", fileName: fileName, mimeType: mimeType)
				}
				, success:
				{ res, data in
					self.checkResponce(data, onSuccess: onSuccess, onFailure: onFailure)
				}
				, failure:
				{ res, err in
#if TARGET_IS_SHARE_EXTENSION
#else
						self.app.networkActivityIndicatorVisible = false
#endif
					onFailure?(err)
			})
			
			req.setTaskDidSendBodyDataBlock(onProgress)
			task.resume()
		} else {
			println(param)

			req.POST("\(apiEndPoint)/send", parameters: param, success:
				{ res, data in
					self.checkResponce(data, onSuccess: onSuccess, onFailure: onFailure)
				}
				, failure:
				{ res, err in
#if TARGET_IS_SHARE_EXTENSION
#else
						self.app.networkActivityIndicatorVisible = false
#endif
					onFailure?(err)
			})
		}
		
	}
	
	func checkConnectionAndReSignIn(username: String, password: String) {
		self.getData(mode: .Test, onSuccess: nil, onFailure:
			{ err in
				if err.code == 0 {
					self.signIn(username: username, password: password, onSuccess: nil, onFailure: nil)
				}
			
		})
	}
	
	func getTimeline(topicid: Int? = nil, maxid: Int? = nil, sinceid: Int? = nil, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.getData(mode: .Timeline, topicid: topicid, maxid: maxid, sinceid: sinceid, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func getTopic(onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.getData(mode: .Topic, tag: "1", onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func getClass(onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.getData(mode: .Class, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func getProfile(#username: String, withTitle: Bool = true, withTimeline: Bool = true, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.getData(mode: .Profile, tag: String(withTitle.hashValue), type: withTimeline.hashValue, username: username, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func getSearchResult(topicid: Int? = nil, maxid: Int? = nil, sinceid: Int? = nil, tag: String? = nil, username: String? = nil, type: TesSoMeSearchType = .All, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		var typeValue: Int? = type.rawValue
		if type == .All {
			typeValue = nil
		}
		self.getData(mode: .SearchResult, maxid: maxid, sinceid: sinceid, tag: tag, username: username, type: typeValue, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func sendMessage(#topicid: Int, message: String, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .Message, target: String(topicid), text: message, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func sendDrawing(#topicid: Int, message: String? = nil, drawing: UIImage, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		let encodedImage = UIImagePNGRepresentation(drawing).base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
		self.sendData(mode: .Drawing, target: String(topicid), text: message, data: encodedImage, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func postFile(#topicid: Int, fileId: Int, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .FilePost, target: String(topicid), data: String(fileId), onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func uploadFile(#fileURL: NSURL, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .FileUpload, fileURL: fileURL, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func uploadFile(#fileURL: NSURL, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil)(topicid: Int) {
		self.sendData(mode: .FileUpload, fileURL: fileURL, onSuccess:
			{ res in
				let id = (((res["data"] as NSArray)[0] as NSDictionary)["id"] as String).toInt()!
				self.postFile(topicid: topicid, fileId: id, onSuccess: onSuccess, onFailure: onFailure)
			}
			, onFailure: onFailure)
	}
	
	func convertDateToTessoAPIStyle(date:NSDate) -> String {
		let dateFormatter = NSDateFormatter()
		dateFormatter.dateFormat = "yyyy_MM_dd_HH"
		
		return dateFormatter.stringFromDate(date)
	}
	
	func addClass(#date: NSDate, text: String, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		
		self.sendData(mode: .EditClass, target: convertDateToTessoAPIStyle(date), text: text, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func removeClass(#date: NSDate, text: String = "", onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .EditClass, target: convertDateToTessoAPIStyle(date), data: "1", onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func updateProfile(nickname: String? = nil, profile: String? = nil, iconURL: NSURL? = nil, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .UpdateProfile, target: nickname, text: profile, fileURL: iconURL, onSuccess: onSuccess, onFailure: onFailure)
	}
	
	func addTitle(#username: String, title: String, onSuccess: ((NSDictionary) -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
		self.sendData(mode: .AddTitle, target: username, text: title, onSuccess: onSuccess, onFailure: onFailure)
	}

	func getMimeType(fromURL fileURL: NSURL) -> String {
		let req = NSURLRequest(URL: fileURL, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 0.1)
		var err: NSError? = nil
		var res: NSURLResponse? = nil
		
		let data = NSURLConnection.sendSynchronousRequest(req, returningResponse: &res, error: &err)
		let mimeType = res?.MIMEType
		
		if mimeType == nil {
			return "application/octet-stream"
		}
		
		return mimeType!
	}
	

}
