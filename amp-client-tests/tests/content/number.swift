//
//  number.swift
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

class numberContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNumberOutletFetchSync() {
        let expectation = self.expectationWithDescription("testNumberOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.number("Number") {
                XCTAssertEqual(value, 123456.0)
            } else {
                XCTFail("number content 'Number' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testNumberOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testNumberOutletFetchAsync")
        
        AMP.collection("test").page("page_001").number("Number") { value in
            XCTAssertEqual(value, 123456.0)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}