//
//  option.swift
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

class optionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testOptionOutletFetchSync() {
        let expectation = self.expectationWithDescription("testOptionOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.selectedOption("option") {
                XCTAssertEqual(value, "2")
            } else {
                XCTFail("option content 'Option' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testOptionOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testOptionOutletFetchAsync")
        
        AMP.collection("test").page("page_001").selectedOption("option") { value in
            XCTAssertEqual(value, "2")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}