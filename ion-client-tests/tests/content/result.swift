//
//  result.swift
//  ion-tests
//
//  Created by Dominik Felber on 25.04.16.
//  Copyright © 2016 anfema GmbH. All rights reserved.
//

import XCTest
import DEjson
@testable import ion_client

class resultTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccess() {
        let expectation = self.expectationWithDescription("testSuccess")
        
        ION.collection("test").page("page_001").outlet("text") { result in
            guard case .Success = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertTrue(result.debugDescription.hasPrefix("SUCCESS: "))
            XCTAssertFalse(result.isFailure)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.optional())
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testFailure() {
        let expectation = self.expectationWithDescription("testFailure")
        
        ION.collection("test").page("page_001").outlet("UnknownOutlet") { result in
            guard case .Success = result else {
                if case .OutletNotFound(let name) = result.error! {
                    XCTAssertTrue(result.debugDescription.hasPrefix("FAILURE: "))
                    XCTAssertTrue(result.isFailure)
                    XCTAssertFalse(result.isSuccess)
                    XCTAssertEqual(name, "UnknownOutlet")
                    XCTAssertNil(result.optional())
                    XCTAssertNil(result.value)
                    XCTAssertNotNil(result.error)
                } else {
                    XCTFail()
                }
                
                expectation.fulfill()
                return
            }
            
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}