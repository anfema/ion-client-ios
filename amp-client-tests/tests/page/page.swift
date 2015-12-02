//
//  page.swift
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

class pageTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPageFetchSync() {
        let expectation = self.expectationWithDescription("testPageFetchSync")
        AMP.resetMemCache()
        
        AMP.collection("test") { collection in
            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.layout == "Layout 001")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPagePositionSync() {
        let expectation1 = self.expectationWithDescription("testPagePositionSync 1")
        let expectation2 = self.expectationWithDescription("testPagePositionSync 2")
        
        AMP.collection("test") { collection in
            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.position == 0)
            expectation1.fulfill()
        }

        AMP.collection("test") { collection in
            let page = collection.page("page_002")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_002")
            XCTAssert(page.position == 1)
            expectation2.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectationWithDescription("testPageFetchAsync")
        
        AMP.collection("test").onError() { error in
            XCTFail()
            expectation.fulfill()
        }.page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.layout == "Layout 001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPagePositionAsync() {
        let expectation1 = self.expectationWithDescription("testPagePositionAync 1")
        let expectation2 = self.expectationWithDescription("testPagePositionAync 2")
        
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.position == 0)
            expectation1.fulfill()
        }
        
        AMP.collection("test").page("page_002") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_002")
            XCTAssert(page.position == 1)
            expectation2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchFail() {
        let expectation = self.expectationWithDescription("testPageFetchFail")
        
        AMP.collection("test").onError() { error in
            if case .PageNotFound(let name) = error {
                XCTAssertEqual(name, "unknown_page")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageParentAsync() {
        let expectation = self.expectationWithDescription("testPageParentAsync")
        
        AMP.collection("test").page("subpage_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "Layout 001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageCount() {
        AMP.collection("test").pageCount(nil) { count in
            XCTAssert(count == 2)
        }
        AMP.collection("test").pageCount("page_002") { count in
            XCTAssert(count == 1)
        }
    }

    func testPageParent() {
        let expectation = self.expectationWithDescription("testPageParent")
        AMP.collection("test").page("subpage_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "Layout 001")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageChild() {
        let expectation = self.expectationWithDescription("testPageChild")
        
        AMP.collection("test").page("page_002") { page in
            guard let child = page.child("subpage_001") else {
                XCTFail("Child not found")
                expectation.fulfill()
                return
            }
            XCTAssert(child.identifier == "subpage_001")
            XCTAssert(child.parent == "page_002")
            XCTAssert(child.layout == "Layout 001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageChildAsync() {
        let expectation = self.expectationWithDescription("testPageChildAsync")
        
        AMP.collection("test").page("page_002").onError() { error in
            print(error)
            XCTFail()
            expectation.fulfill()
        }.child("subpage_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "Layout 001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageChildFail() {
        let expectation = self.expectationWithDescription("testPageChildFail")
        
        AMP.config.errorHandler = { (collection, error) in
            if case .InvalidPageHierarchy(let parent, let child) = error {
                XCTAssert(parent == "page_002")
                XCTAssert(child == "page_001")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("test").page("page_002").child("page_001") { page in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
    
//    func testPageEnumeration() {
//        let expectation = self.expectationWithDescription("testPageEnumeration")
//
//        var pageCount = 0;
//        AMP.collection("test").pages { page in
//            XCTAssert(page.position == pageCount)
//            pageCount++
//            if (page.identifier != "page_001") && (page.identifier != "page_002") {
//                XCTFail()
//            }
//            if (pageCount == 2) {
//                expectation.fulfill()
//            }
//        }
//
//        self.waitForExpectationsWithTimeout(4.0, handler: nil)
//        XCTAssert(pageCount == 2)
//    }
    
    func testSubPageEnumeration() {
        let expectation = self.expectationWithDescription("testSubPageEnumeration")
        
        AMP.collection("test").page("page_002").children { page in
            XCTAssert(page.identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testSubPageList() {
        let expectation = self.expectationWithDescription("testSubPageList")
        
        AMP.collection("test").page("page_002").childrenList { list in
            XCTAssert(list.count == 1)
            XCTAssert(list[0].identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testOutletExists() {
        let expectation = self.expectationWithDescription("testOutletExists")
        
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.outletExists("Text") == true)
            XCTAssert(page.outletExists("Unknown_Outlet") == false)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testOutletExistsAsync() {
        let expectation = self.expectationWithDescription("testOutletExistsAsync")
        
        AMP.collection("test").page("page_001").outletExists("Text") { exists in
            XCTAssertTrue(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testOutletDoesNotExistAsync() {
        let expectation = self.expectationWithDescription("testOutletDoesNotExistAsync")
        
        AMP.collection("test").page("page_001").outletExists("Unknown_Outlet") { exists in
            XCTAssertFalse(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testCancelablePage() {
        AMP.resetMemCache()
        XCTAssert(AMP.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCancelableCollection")
        
        AMP.collection("test") { collection in
            // now this one collection is in the cache and no page
            XCTAssert(AMP.collectionCache.count == 1)
            XCTAssert(collection.pageCache.count == 0)
            
            collection.page("page_001") { page in
                // now we have one page
                XCTAssert(collection.pageCache.count == 1)
            
                // let's get a cancelable fork
                let p = page.cancelable()
                
                // now we have 2 pages in the cache
                XCTAssert(collection.pageCache.count == 2)
                
                // suspend the work queue to be able to queue deterministically
                dispatch_suspend(p.workQueue)
                
                // cancel the fork
                p.cancel()
                
                // on completion will now be called after cancelling
                p.onCompletion() { page, completed in
                    XCTAssert(completed == false)
                    // cancel/finish has happened here already so only the original page should be in the cache
                    dispatch_async(p.workQueue) {
                        XCTAssert(collection.pageCache.count == 1)
                        expectation.fulfill()
                    }
                }
                
                // now start the thing
                dispatch_resume(p.workQueue)
            }
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

}
