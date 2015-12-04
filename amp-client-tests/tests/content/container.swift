//
//  container.swift
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

class containerContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testContainerOutletFetchSync() {
        let expectation = self.expectationWithDescription("testContainerOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let children = page.children("layout-001") {
                XCTAssertEqual(children.count, 10)
            } else {
                XCTFail("container content 'Layout 001' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testContainerOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testContainerOutletFetchAsync")
        
        AMP.collection("test").page("page_001").children("layout-001") { children in
            XCTAssertEqual(children.count, 10)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testContainerOutletSubscripting() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").outlet("layout-001") { outlet in
            if case let container as AMPContainerContent = outlet {
                XCTAssertEqual(container.children.count, 10)
                XCTAssertNotNil(container[0])
                XCTAssertNil(container[10])
            } else {
                XCTFail("container content 'Layout 001' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}