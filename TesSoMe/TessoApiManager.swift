//
//  TessoApiManager.swift
//  TesSoMe
//
//  Created by Yuki Mizuno on 2014/09/13.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit

class TessoApiManager: NSObject {
    let apiEndPoint = "https://tesso.pw/sns/api"
    
    func signIn(#userId: String, password: String, onSuccess: (() -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
        var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPShouldSetCookies = true
        let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
        req.responseSerializer = AFHTTPResponseSerializer()
        req.POST("https://tesso.pw/users/sign_in", parameters: [ "data[User][username]":userId, "data[User][password]":password], success: {
            res, data in
            if res.response!.URL == NSURL(string: "https://tesso.pw/sns") && onSuccess != nil {
                onSuccess()
            } else if onFailure != nil {
                let err = NSError()
                onFailure(err)
            }
            }, failure: {
                res, err in
                if onFailure != nil {
                    onFailure(err)
                }
        })
    }
    
    func signOut(onSuccess: (() -> Void)! = nil, onFailure: ((NSError) -> Void)! = nil) {
        var url = NSURL(string: "https://tesso.pw/users/sign_out")
        var req = NSMutableURLRequest(URL: url)
        NSURLConnection.sendAsynchronousRequest(req, queue: NSOperationQueue.mainQueue(), completionHandler: {
        res, data, err in
            if err != nil && onFailure != nil {
                onFailure(err)
            } else if onSuccess != nil {
                onSuccess()
            }
        })
    }
    
    func getData(#mode: Int, topicid: Int? = nil, maxid: Int? = nil, sinceid: Int? = nil, tag: String? = nil, username: String? = nil, type: String? = nil, onSuccess: ((NSURLSessionDataTask!, AnyObject!) -> Void)! = nil, onFailure: ((NSURLSessionDataTask!, NSError!) -> Void)! = nil) {
        var sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.HTTPShouldSetCookies = true
        let req = AFHTTPSessionManager(sessionConfiguration: sessionConfig)
        req.responseSerializer.acceptableContentTypes = NSSet(object: "text/html")
        
        var param = ["mode": mode as AnyObject]
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
        req.GET("\(apiEndPoint)/get", parameters: param, success: onSuccess, failure: onFailure)
    }
    
    
}
