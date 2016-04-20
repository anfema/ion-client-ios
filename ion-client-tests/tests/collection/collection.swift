//
//  collection.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class collectionTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCollectionFetch() {
        let expectation = self.expectationWithDescription("testCollectionFetch")
        
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("testCollectionFetchError")
        
        ION.collection("gnarf") { result in
            guard case .Success = result else {
                if case .CollectionNotFound(let name) = result.error! {
                    XCTAssertEqual(name, "gnarf")
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionFetchNotAllowed() {
        guard self.mock else {
            return
        }
        
        let expectation = self.expectationWithDescription("testCollectionFetchNotAllowed")
        
        ION.collection("notallowed") { result in
            guard case .Success = result else {
                if case .NotAuthorized = result.error! {
                    // ok
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionMetaPath() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")

        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            collection.metaPath("subpage_001") { result in
                guard case .Success(let path) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                if path.count == 2 {
                    XCTAssert(path[0].identifier == "page_002")
                    XCTAssert(path[1].identifier == "subpage_001")
                } else {
                    XCTFail()
                }
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionMetaList() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")
        
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if let list = collection.metadataList(nil) {
                if list.count == 2 {
                    XCTAssert(list[0].identifier == "page_001")
                    XCTAssert(list[1].identifier == "page_002")
                } else {
                    XCTFail()
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
        
        ION.collection("test").leaves(nil) { pages in
            if pages.count == 2 {
                XCTAssert(pages[0].identifier == "page_001")
                XCTAssert(pages[1].identifier == "subpage_001")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCollectionDownload() {
        let expectation = self.expectationWithDescription("testCollectionDownload")
        ION.resetDiskCache()
        
        ION.collection("test").download { success in
            XCTAssertTrue(success)
            ION.collection("test").download { success in
                XCTAssertTrue(success)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        ION.resetDiskCache()
        ION.resetMemCache()
    }

    func testCancelableCollection() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCancelableCollection")
        
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            // now this one collection is in the cache
            XCTAssert(ION.collectionCache.count == 1)
            
            // let's get a cancelable fork
            let c = collection.cancelable()
            
            // now we have 2 collections in the cache
            XCTAssert(ION.collectionCache.count == 2)
            
            // on completion will now be called after cancelling
            c.onCompletion() { collection, completed in
                XCTAssert(completed == false)
                // cancel/finish has happened here already so only the original collection should be in the cache
                dispatch_async(c.workQueue) {
                    XCTAssert(ION.collectionCache.count == 1)
                    expectation.fulfill()
                }
            }
            
            // cancel the fork
            c.cancel()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testCollectionCompletion() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCollectionCompletion")
        var page1:IONPage? = nil
        var page2:IONPage? = nil

        let collection = ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                return
            }

            page1 = collection.page("page_001")
            collection.page("page_002") { result in
                guard case .Success(let page) = result else {
                    XCTFail()
                    return
                }

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
        
        ION.collection("test").waitUntilReady{ collection in
            XCTAssertNotNil(collection)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testWaitUntilReady2() {
        let expectation = self.expectationWithDescription("testWaitUntilReady2")
        
        ION.collection("gnarf").waitUntilReady{ result in
            guard case .Success(let collection) = result else {
                if case .DidFail = result.error! {
                    // ok
                } else {
                    print(result.error)
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail("expected to fail. returned \(collection) instead")
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testCollectionPages(){
        let expectation = self.expectationWithDescription("testCollectionPages")
        
        var pages = 0
        
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            collection.pages { result in
                guard case .Success(let page) = result else {
                    XCTFail()
                    pages += 1
                    
                    // page_001 and page_002
                    if pages == 2
                    {
                        expectation.fulfill()
                    }
                    return
                }

                XCTAssertNotNil(page)
                XCTAssert(page.isReady == true)
                
                pages += 1
                
                // page_001 and page_002
                if pages == 2
                {
                    expectation.fulfill()
                }
            }
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testPageByIndex(){
        let expectation = self.expectationWithDescription("testPageByIndex")

        ION.collection("test").waitUntilReady() { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

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
            
            page.waitUntilReady() { result in
                guard case .Success(let loadedPage) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertEqual(loadedPage.identifier, "page_002")
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

