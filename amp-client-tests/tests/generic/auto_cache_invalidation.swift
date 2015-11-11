//
//  auto_cache_invalidation.swift
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

class autoCacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionFetchNoTimeout() {
        let expectation = self.expectationWithDescription("testCollectionFetchNoTimeout")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.collection("test") { collection2 in
                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionFetchWithTimeout() {
        let expectation = self.expectationWithDescription("testCollectionFetchWithTimeout")
        AMP.config.cacheTimeout = 2
        AMP.config.lastOnlineUpdate = nil
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            sleep(3)
            AMP.collection("test") { collection2 in
                XCTAssert(collection.lastUpdate != collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        AMP.config.cacheTimeout = 600
    }

    
}
