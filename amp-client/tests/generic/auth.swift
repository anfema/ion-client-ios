//
//  amp_clientTests.swift
//  amp-clientTests
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import XCTest
@testable import ampclient

class authTests: DefaultXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let expectation = self.expectationWithDescription("login")
        
        AMP.login("admin@anfe.ma", password: "test") { success in
            XCTAssert(success)
            XCTAssertNotNil(AMP.config.sessionToken)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLoginFailure() {
        let expectation = self.expectationWithDescription("login")
        
        AMP.login("admin@anfe.ma", password: "wrongpassword") { success in
            XCTAssert(!success)
            XCTAssertNil(AMP.config.sessionToken)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
