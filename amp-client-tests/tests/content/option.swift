//
//  option.swift
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

class optionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testOptionOutletFetchSync() {
        let expectation = self.expectationWithDescription("testOptionOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let value) = page.selectedOption("option") {
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
        
        ION.collection("test").page("page_001").selectedOption("option") { result in
            guard case .Success(let value) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(value, "2")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}