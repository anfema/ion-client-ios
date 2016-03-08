//
//  connection.swift
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

class connectionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testConnectionOutletFetchSync() {
        let expectation = self.expectationWithDescription("testConnectionOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                return
            }
            
            if case .Success(let link) = page.link("connection") {
                XCTAssertEqual(link, NSURL(string: "ion://testconnection124"))
            } else {
                XCTFail("connection content 'Connection' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testConnectionOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testConnectionOutletFetchAsync")
        
        ION.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let link) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(link, NSURL(string: "ion://testconnection124"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}