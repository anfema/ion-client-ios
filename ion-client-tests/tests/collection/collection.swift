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
        let expectation = self.expectation(description: "testCollectionFetch")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectation(description: "testCollectionFetchError")
        
        ION.collection("gnarf") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.collectionNotFound(let name) = result.error! {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCollectionFetchNotAllowed() {
        guard self.mock else {
            return
        }
        
        let expectation = self.expectation(description: "testCollectionFetchNotAllowed")
        
        ION.collection("notallowed") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.notAuthorized = result.error! {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCollectionMetaPath() {
        let expectation = self.expectation(description: "testCollectionMetaPath")

        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            collection.metaPath("subpage_001") { result in
                guard case .success(let path) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testCollectionMetaList() {
        let expectation = self.expectation(description: "testCollectionMetaPath")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .success(let list) = collection.childMetadataList(forParent: nil) else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            if list.count == 2 {
                XCTAssert(list[0].identifier == "page_001")
                XCTAssert(list[1].identifier == "page_002")
            } else {
                XCTFail()
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testLeavesList() {
        let expectation = self.expectation(description: "testLeavesList")
        
        ION.collection("test").leaves(forParent: nil) { pages in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            if pages.count == 2 {
                XCTAssert(pages[0].identifier == "page_001")
                XCTAssert(pages[1].identifier == "subpage_001")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testCollectionDownload() {
        let expectation = self.expectation(description: "testCollectionDownload")
        ION.resetDiskCache()
        
        ION.collection("test").download { success in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssertTrue(success)
            ION.collection("test").download { success in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                XCTAssertTrue(success)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
        ION.resetDiskCache()
        ION.resetMemCache()
    }

    func testCancelableCollection() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectation(description: "testCancelableCollection")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
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
                c.workQueue.async {
                    XCTAssert(ION.collectionCache.count == 1)
                    expectation.fulfill()
                }
            }
            
            // cancel the fork
            c.cancel()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testCollectionCompletion() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectation(description: "testCollectionCompletion")
        var page1:IONPage? = nil
        var page2:IONPage? = nil

        let collection = ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                return
            }

            page1 = collection.page("page_001")
            collection.page("page_002") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let page) = result else {
                    XCTFail()
                    return
                }

                page2 = page
            }
        }
        
        collection.onCompletion { collection, completed in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testWaitUntilReady() {
        let expectation = self.expectation(description: "testWaitUntilReady")
        
        ION.collection("test").waitUntilReady{ collection in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssertNotNil(collection)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testWaitUntilReady2() {
        let expectation = self.expectation(description: "testWaitUntilReady2")
        
        ION.collection("gnarf").waitUntilReady{ result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                if case IONError.didFail = result.error! {
                    // ok
                } else {
                    print(result.error as Any)
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail("expected to fail. returned \(collection) instead")
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testCollectionPages(){
        let expectation = self.expectation(description: "testCollectionPages")
        
        var pages = 0
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                XCTFail()
                expectation.fulfill()
                return
            }
            
            collection.pages { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let page) = result else {
                    
                    // Test if the correct response queue is used
                    XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                    
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testPageByIndex(){
        let expectation = self.expectation(description: "testPageByIndex")

        ION.collection("test").waitUntilReady() { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if let _ = collection.page(atPosition: -1)
            {
                XCTFail()
                return
            }

            if let _ = collection.page(atPosition: 2)
            {
                XCTFail()
                return
            }
            
            guard let page = collection.page(atPosition: 1) else
            {
                XCTFail()
                return
            }
            
            page.waitUntilReady() { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let loadedPage) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertEqual(loadedPage.identifier, "page_002")
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
}

