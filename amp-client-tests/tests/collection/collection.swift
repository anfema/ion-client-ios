//
//  collection.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import amp_client

class collectionTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCollectionFetch() {
        let expectation = self.expectationWithDescription("testCollectionFetch")
        
        AMP.config.errorHandler = { collection, error in
            XCTFail()
            expectation.fulfill()
        }
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("testCollectionFetchError")
        
        AMP.config.errorHandler = { (collectionID, error) in
            XCTAssertEqual(collectionID, "gnarf")
            if case .CollectionNotFound(let name) = error {
                XCTAssertEqual(name, "gnarf")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("gnarf") { collection in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }

    func testCollectionFetchNotAllowed() {
        guard self.mock else {
            return
        }
        
        let expectation = self.expectationWithDescription("testCollectionFetchNotAllowed")
        
        AMP.config.errorHandler = { (collectionID, error) in
            XCTAssertEqual(collectionID, "notallowed")
            if case .NotAuthorized = error {
                // ok
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("notallowed") { collection in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }

    func testCollectionMetaPath() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")

        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            collection.metaPath("subpage_001") { path in
                XCTAssert(path.count == 2)
                if path.count == 2 {
                    XCTAssert(path[0].identifier == "page_002")
                    XCTAssert(path[1].identifier == "subpage_001")
                }
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionMetaList() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            if let list = collection.metadataList(nil) {
                XCTAssert(list.count == 2)
                if list.count == 2 {
                    XCTAssert(list[0].identifier == "page_001")
                    XCTAssert(list[1].identifier == "page_002")
                }
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLeavesList() {
        let expectation = self.expectationWithDescription("testLeavesList")
        
        AMP.collection("test").leaves(nil) { pages in
            XCTAssert(pages.count == 2)
            if pages.count == 2 {
                XCTAssert(pages[0].identifier == "page_001")
                XCTAssert(pages[1].identifier == "subpage_001")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCollectionDownload() {
        let expectation = self.expectationWithDescription("testCollectionDownload")
        AMP.resetDiskCache()
        
        AMP.collection("test").download { success in
            XCTAssertTrue(success)
            AMP.collection("test").download { success in
                XCTAssertTrue(success)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        AMP.resetDiskCache()
        AMP.resetMemCache()
    }

    func testCancelableCollection() {
        AMP.resetMemCache()
        XCTAssert(AMP.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCancelableCollection")
        
        AMP.collection("test") { collection in
            // now this one collection is in the cache
            XCTAssert(AMP.collectionCache.count == 1)
            
            // let's get a cancelable fork
            let c = collection.cancelable()
            
            // now we have 2 collections in the cache
            XCTAssert(AMP.collectionCache.count == 2)
            
            // on completion will now be called after cancelling
            c.onCompletion() { collection, completed in
                XCTAssert(completed == false)
                // cancel/finish has happened here already so only the original collection should be in the cache
                dispatch_async(c.workQueue) {
                    XCTAssert(AMP.collectionCache.count == 1)
                    expectation.fulfill()
                }
            }
            
            // cancel the fork
            c.cancel()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCollectionCompletion() {
        AMP.resetMemCache()
        XCTAssert(AMP.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCollectionCompletion")
        var page1:AMPPage? = nil
        var page2:AMPPage? = nil

        let collection = AMP.collection("test") { collection in
            page1 = collection.page("page_001")
            collection.page("page_002") { page in
                page2 = page
            }
        }
        
        collection.onCompletion { collection, completed in
            XCTAssert(completed == true)
            if let page1 = page1 {
                XCTAssert(page1.hasFailed == false)
                XCTAssert(page1.isReady == true)
            } else {
                XCTFail("page1 not loaded")
            }
            
            if let page2 = page2 {
                XCTAssert(page2.hasFailed == false)
                XCTAssert(page2.isReady == true)
            } else {
                XCTFail("page2 not loaded")
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testWaitUntilReady() {
        let expectation = self.expectationWithDescription("testWaitUntilReady")
        
        AMP.collection("test").waitUntilReady{ collection in
            XCTAssertNotNil(collection)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testWaitUntilReady2() {
        let expectation = self.expectationWithDescription("testWaitUntilReady2")
        
        AMP.config.errorHandler = { (str, error) in
            AMP.config.resetErrorHandler()
            
            guard case AMPError.CollectionNotFound(let e) = error else
            {
                XCTFail("wrong error")
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(e)
            expectation.fulfill()
        }
        
        AMP.collection("gnarf").waitUntilReady{ collection in
            XCTFail("expected to fail. returned \(collection) instead")
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testCollectionPages(){
        let expectation = self.expectationWithDescription("testCollectionPages")
        
        var pages = 0
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            
            collection.pages({ page in
                XCTAssertNotNil(page)
                XCTAssert(page.isReady == true)
                
                pages += 1
                
                // page_001 and page_002
                if pages == 2
                {
                    expectation.fulfill()
                }
            })
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testPageByIndex(){
        let expectation = self.expectationWithDescription("testPageByIndex")

        AMP.collection("test").waitUntilReady() { collection in
            if let _ = collection.page(-1)
            {
                XCTFail()
                return
            }

            if let _ = collection.page(2)
            {
                XCTFail()
                return
            }
            
            guard let page = collection.page(1) else
            {
                XCTFail()
                return
            }
            
            page.waitUntilReady() { loadedPage in
                XCTAssertEqual(loadedPage.identifier, "page_002")
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

