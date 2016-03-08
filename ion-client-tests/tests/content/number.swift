//
//  number.swift
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

class numberContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNumberOutletFetchSync() {
        let expectation = self.expectationWithDescription("testNumberOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                return
            }

            if case .Success(let value) = page.number("number") {
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
        
        ION.collection("test").page("page_001").number("number") { result in
            guard case .Success(let value) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(value, 123456.0)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}