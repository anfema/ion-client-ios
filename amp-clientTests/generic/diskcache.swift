//
//  amp_clientTests.swift
//  amp-clientTests
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import XCTest
@testable import ampclient

class diskcacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCollectionDiskCache() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.resetMemCache()
            AMP.collection("test") { collection2 in
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2 !== collection)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testCollectionDiskCacheClean() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test") { collection2 in
                XCTAssert(collection2 !== collection)
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedDescending)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testCollectionDiskCacheUpdate() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.refreshCache() { updatedCollection in
                if collection.identifier == updatedCollection.identifier {
                    XCTAssertNotNil(updatedCollection.lastUpdate)
                    XCTAssert(updatedCollection !== collection)
                    XCTAssert(updatedCollection.lastUpdate!.compare(collection.lastUpdate!) == .OrderedDescending)
                    let collection2 = AMP.collection("test")
                    XCTAssert(collection2 === updatedCollection)
                    expectation.fulfill()
                }
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageDiskCache() {
        let expectation = self.expectationWithDescription("fetch page")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2 !== page)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testPageDiskCacheClean() {
        let expectation = self.expectationWithDescription("fetch page")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssert(page2 !== page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedDescending)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testPageDiskCacheUpdate() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.refreshCache() { updatedCollection in
                if updatedCollection.identifier == "test" {
                    updatedCollection.page("page_001") { updatedPage in
                        XCTAssertNotNil(updatedPage.lastUpdate)
                        XCTAssert(updatedPage !== page)
                        
                        // This works different from collection:
                        // - Collection is always updated, page not
                        // - Page will be refetched if it actually changed
                        // As nobody is changing the page we assume it will not be refetched!
                        // TODO: Test other case (page has changed)
                        XCTAssert(updatedPage.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                        let page2 = AMP.collection("test").page("page_001")
                        XCTAssert(page2 === updatedPage)
                        expectation.fulfill()
                    }
                }
            }
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

}
