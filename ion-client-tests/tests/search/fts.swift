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
        let expectation = self.expectation(description: "testCollectionSearch")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search(for: "ullamcorper")
            XCTAssert(items.count == 4)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCollectionSearchExclusion() {
        let expectation = self.expectation(description: "testCollectionSearchExclusion")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search(for: "ullamcorper -nulla")
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testCollectionStatement() {
        let expectation = self.expectation(description: "testCollectionStatement")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search(for: "donec duis")
            XCTAssert(items.count == 3)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testCollectionPhrase() {
        let expectation = self.expectation(description: "testCollectionPhrase")
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search(for: "\"donec duis\"")
            XCTAssert(items.count == 0)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    func testDownloadFTS()
    {
        let consumer = NotificationConsumer(notification: Notification.ftsDatabaseDidUpdate)
        let expectation = self.expectation(description: "testDownloadFTS")
        
        XCTAssertFalse(consumer.notificationWasReceived)
        XCTAssertNil(consumer.notificationObject)
        
        ION.config.enableFTS("test")
        XCTAssertTrue(ION.config.isFTSEnabled("test"))
        
        ION.downloadFTSDB(forCollection: "test") {
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
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
        let expectation = self.expectation(description: "testGetSearchHandle")
        
        ION.config.disableFTS("test")
        XCTAssertFalse(ION.config.isFTSEnabled("test"))
        
        ION.collection("test").getSearchHandle { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.didFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
}


// Helper class that can listen for notifications
class NotificationConsumer {
    
    var notificationWasReceived = false
    var notificationUserInfo: [AnyHashable: Any]?
    var notificationObject: Any?
    
    init(notification: Foundation.Notification.Name) {
        NotificationCenter.default.addObserver(self, selector: #selector(NotificationConsumer.onNotification(_:)), name: notification, object: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    @objc func onNotification(_ notification: Foundation.Notification) {
        notificationObject = notification.object
        notificationUserInfo = notification.userInfo
        notificationWasReceived = true
    }
}

