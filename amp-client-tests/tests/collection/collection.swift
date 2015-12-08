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
    
    func testCollectionMetaPath() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")

        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            collection.metaPath("subpage_001") { path in
                XCTAssert(path.count == 2)
                XCTAssert(path[0].identifier == "page_002")
                XCTAssert(path[1].identifier == "subpage_001")
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
                XCTAssert(list[0].identifier == "page_001")
                XCTAssert(list[1].identifier == "page_002")
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
            XCTAssert(pages[0].identifier == "page_001")
            XCTAssert(pages[1].identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCollectionDownload() {
        let expectation = self.expectationWithDescription("testCollectionDownload")
        
        AMP.collection("test").download { success in
            XCTAssertTrue(success)
            expectation.fulfill()
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
            
            // suspend the work queue to be able to queue deterministically
            dispatch_suspend(c.workQueue)

            // cancel the fork
            c.cancel()
            
            // on completion will now be called after cancelling
            c.onCompletion() { collection, completed in
                XCTAssert(completed == false)
                // cancel/finish has happened here already so only the original collection should be in the cache
                dispatch_async(c.workQueue) {
                    XCTAssert(AMP.collectionCache.count == 1)
                    expectation.fulfill()
                }
            }
            
            // now start the thing
            dispatch_resume(c.workQueue)
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
}

