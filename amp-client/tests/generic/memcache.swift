//
//  memcache.swift
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

class memcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionMemcache() {
        let expectation = self.expectationWithDescription("testCollectionMemcache")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            let collection2 = AMP.collection("test")
            XCTAssert(collection2 === collection)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }   
}
