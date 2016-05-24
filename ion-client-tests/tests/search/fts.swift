//
//  fts.swift
//  ion-tests
//
//  Created by Johannes Schriewer on 12/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class ftsTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
        ION.config.enableFTS("test")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionSearch() {
        let expectation = self.expectationWithDescription("testCollectionSearch")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("ullamcorper")
            XCTAssert(items.count == 4)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testCollectionSearchExclusion() {
        let expectation = self.expectationWithDescription("testCollectionSearchExclusion")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("ullamcorper -nulla")
            XCTAssert(items.count == 1)
            
            guard let item = items.first else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(item.html(), "<p>Donec <strong>ullamcorper</strong></p>")
            XCTAssertEqual(item.attributedString().string, "Donec ullamcorper\n\n")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testCollectionStatement() {
        let expectation = self.expectationWithDescription("testCollectionStatement")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("donec duis")
            XCTAssert(items.count == 3)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testCollectionPhrase() {
        let expectation = self.expectationWithDescription("testCollectionPhrase")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("\"donec duis\"")
            XCTAssert(items.count == 0)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    func testDownloadFTS()
    {
        let consumer = NotificationConsumer(notification: Notification.ftsDatabaseDidUpdate)
        let expectation = self.expectationWithDescription("testDownloadFTS")
        
        XCTAssertFalse(consumer.notificationWasReceived)
        XCTAssertNil(consumer.notificationObject)
        
        ION.config.enableFTS("test")
        XCTAssertTrue(ION.config.isFTSEnabled("test"))
        
        ION.downloadFTSDB("test") {
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            // notificationWasReceived should be true when notification was sent
            XCTAssertTrue(consumer.notificationWasReceived)
            XCTAssertNotNil(consumer.notificationObject)
            
            // Extract collection identifier from notification.
            guard let collectionIdentifier = consumer.notificationObject as? String else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(collectionIdentifier, "test")
            
            // TODO: Test if download was successful
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
        
    
    func testEnableDisableSearchHandle()
    {
        ION.config.enableFTS("test")
        XCTAssertTrue(ION.config.isFTSEnabled("test"))
        
        ION.config.disableFTS("test")
        XCTAssertFalse(ION.config.isFTSEnabled("test"))
    }
    
    
    func testGetSearchHandle()
    {
        let expectation = self.expectationWithDescription("testGetSearchHandle")
        
        ION.config.disableFTS("test")
        XCTAssertFalse(ION.config.isFTSEnabled("test"))
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}


// Helper class that can listen for notifications
class NotificationConsumer {
    
    var notificationWasReceived = false
    var notificationUserInfo: [NSObject: AnyObject]?
    var notificationObject: AnyObject?
    
    init(notification: String) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NotificationConsumer.onNotification(_:)), name: notification, object: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    
    @objc func onNotification(notification: NSNotification) {
        notificationObject = notification.object
        notificationUserInfo = notification.userInfo
        notificationWasReceived = true
    }
}

