//
//  diskcache.swift
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

class diskcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionDiskCache() {
        let expectation = self.expectationWithDescription("testCollectionDiskCache")
        AMP.resetMemCache()
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
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionDiskCacheClean() {
        let expectation = self.expectationWithDescription("testCollectionDiskCacheClean")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test") { collection2 in
                XCTAssert(collection2 !== collection)
                XCTAssert(collection2 == collection)
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedDescending)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageDiskCache() {
        let expectation = self.expectationWithDescription("testPageDiskCache")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageDiskCacheClean() {
        let expectation = self.expectationWithDescription("testPageDiskCacheClean")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedDescending)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
