//
//  base.swift
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

class contentBaseTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testOutletFetchSync() {
        let expectation = self.expectationWithDescription("testOutletFetchSync")
        
        AMP.collection("test").page("page_001"){ page in
            if let _ = page.outlet("Text") {
                // all ok
            } else {
                XCTFail("outlet for name 'text' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testOutletFetchAsync")
        
        AMP.collection("test").page("page_001").outlet("Text") { text in
            XCTAssertNotNil(text)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testOutletFetchFail() {
        let expectation = self.expectationWithDescription("testOutletFetchFail")
        
        AMP.collection("test").page("page_001").onError() { error in
            if case .OutletNotFound(let name) = error {
                XCTAssertEqual(name, "UnknownOutlet")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.outlet("UnknownOutlet") { text in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

}