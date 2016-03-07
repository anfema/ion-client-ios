//
//  connection.swift
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

class connectionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testConnectionOutletFetchSync() {
        let expectation = self.expectationWithDescription("testConnectionOutletFetchSync")
        
        AMP.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                return
            }
            
            if case .Success(let link) = page.link("connection") {
                XCTAssertEqual(link, NSURL(string: "amp://testconnection124"))
            } else {
                XCTFail("connection content 'Connection' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testConnectionOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testConnectionOutletFetchAsync")
        
        AMP.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let link) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(link, NSURL(string: "amp://testconnection124"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}