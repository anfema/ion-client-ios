//
//  flag.swift
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

class flagContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFlagOutletFetchSync() {
        let expectation = self.expectationWithDescription("testFlagOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.isSet("Flag") {
                XCTAssertEqual(value, false)
            } else {
                XCTFail("flag content 'Flag' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testFlagOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testFlagOutletFetchAsync")
        
        AMP.collection("test").page("page_001").isSet("Flag") { value in
            XCTAssertEqual(value, false)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}