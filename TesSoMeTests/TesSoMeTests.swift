//
//  TesSoMeTests.swift
//  TesSoMeTests
//
//  Created by Yuki Mizuno on 2014/09/12.
//  Copyright (c) 2014年 Yuki Mizuno. All rights reserved.
//

import UIKit
import XCTest

class TesSoMeTests: XCTestCase {
	let userId = "YOUR_USERID_HERE"
	let password = "YOUR_PASSWORD_HERE"
	
	let apiMgr = TessoApiManager()
	
	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
		let apiExpectation = self.expectationWithDescription("api signin")
		
		apiMgr.signIn(userId: self.userId, password: self.password, onSuccess: {
			XCTAssert(true, "Pass")
			apiExpectation.fulfill()
			}, onFailure: { err in
				XCTAssert(false, "Fail")
		})
		
		self.waitForExpectationsWithTimeout(1.0, handler: {err in
		})
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		apiMgr.signOut(onSuccess: nil, onFailure: nil)
		super.tearDown()
	}
	
	func testExample() {
		// This is an example of a functional test case.
		XCTAssert(true, "Pass")
	}
	
	func testGetTimeline() {
		let apiExpectation = self.expectationWithDescription("api getTimeline")
		
		apiMgr.getTimeline(topicid: 1, onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	
	func testGetTopic() {
		let apiExpectation = self.expectationWithDescription("api getTopic")
		
		apiMgr.getTopic(onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	
	func testGetClass() {
		let apiExpectation = self.expectationWithDescription("api getClass")
		
		apiMgr.getClass(onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	
	func testGetProfile() {
		let apiExpectation = self.expectationWithDescription("api getProfile")
		
		apiMgr.getProfile(username: "eula", onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	
	func testGetSearchResult() {
		let apiExpectation = self.expectationWithDescription("api getSearchResult")
		
		apiMgr.getSearchResult(username: "eula", onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}

	func testSendMessageTest() {
		let apiExpectation = self.expectationWithDescription("api sendMessageTest")
		
		apiMgr.sendMessage(topicid: 1, message: "Nemu", onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	
	func testAddTitle() {
		let apiExpectation = self.expectationWithDescription("api addTitle")
		apiMgr.addTitle(username: "eula", title: "神の子", onSuccess:
			{
				data in
				XCTAssert(true, "Pass")
				apiExpectation.fulfill()
			}
			, onFailure:
			{
				err in
				XCTAssert(false, "Fail")
		})
		self.waitForExpectationsWithTimeout(3.0, handler: {err in
		})
	}
	


	func testPerformanceExample() {
		// This is an example of a performance test case.
		self.measureBlock() {
			// Put the code you want to measure the time of here.
			//XCTAssertEqual("a", "b", "err")
		}
	}
	
}
