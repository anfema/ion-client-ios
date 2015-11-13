//
//  auth.swift
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

class authTests: DefaultXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let expectation = self.expectationWithDescription("testLoginSuccess")
        
        AMP.login("admin@anfe.ma", password: "test") { success in
            XCTAssert(success)
            XCTAssertNotNil(AMP.config.sessionToken)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLoginFailure() {
        let expectation = self.expectationWithDescription("testLoginFailure")
        
        AMP.login("admin@anfe.ma", password: "wrongpassword") { success in
            XCTAssert(!success)
            XCTAssertNil(AMP.config.sessionToken)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}