//
//  auth.swift
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

class authTests: DefaultXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testLoginSuccess() {
        let expectation = self.expectationWithDescription("testLoginSuccess")
        
        ION.login("admin@anfe.ma", password: "test") { success in
            XCTAssert(success)
            XCTAssertNotNil(ION.config.sessionToken)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLoginFailure() {
        if !self.mock {
            let expectation = self.expectationWithDescription("testLoginFailure")
        
            ION.login("admin@anfe.ma", password: "wrongpassword") { success in
                XCTAssert(!success)
                XCTAssertNil(ION.config.sessionToken)
                expectation.fulfill()
            }
            self.waitForExpectationsWithTimeout(1.0, handler: nil)
        }
    }
}
