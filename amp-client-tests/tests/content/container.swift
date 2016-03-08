//
//  container.swift
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

class containerContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testContainerOutletFetchSync() {
        let expectation = self.expectationWithDescription("testContainerOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let children) = page.children("layout-001") {
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
        
        ION.collection("test").page("page_001").children("layout-001") { result in
            guard case .Success(let children) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(children.count, 10)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testContainerOutletSubscripting() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        ION.collection("test").page("page_001").outlet("layout-001") { result in
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case let container as IONContainerContent = outlet {
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