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
@testable import ampclient

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
        }.onError() { error in
            XCTFail()
            expectation.fulfill()
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
        let page = AMP.collection("test").page("subpage_001")
        XCTAssertNotNil(page)
        XCTAssert(page.identifier == "subpage_001")
        XCTAssert(page.parent == "page_002")
        XCTAssert(page.layout == "Layout 001")
    }

    func testPageChild() {
        let expectation = self.expectationWithDescription("testPageChild")
        
        AMP.collection("test").page("page_002").child("subpage_001") { page in
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
    
    func testPageEnumeration() {
        let expectation = self.expectationWithDescription("testPageEnumeration")

        var pageCount = 0;
        AMP.collection("test").pages { page in
            pageCount++
            if (page.identifier != "page_001") && (page.identifier != "page_002") {
                XCTFail()
            }
            if (pageCount == 2) {
                dispatch_async(AMP.config.responseQueue) {
                    expectation.fulfill()
                }
            }
        }

        self.waitForExpectationsWithTimeout(4.0, handler: nil)
        XCTAssert(pageCount == 2)
    }
    
    func testSubPageEnumeration() {
        let expectation = self.expectationWithDescription("testSubPageEnumeration")
        
        AMP.collection("test").page("page_002").children { page in
            XCTAssert(page.identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}
