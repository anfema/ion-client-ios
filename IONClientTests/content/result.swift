//
//  result.swift
//  ion-tests
//
//  Created by Dominik Felber on 25.04.16.
//  Copyright © 2016 anfema GmbH. All rights reserved.
//

import XCTest
@testable import IONClient

class resultTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSuccess() {
        let expectation = self.expectation(description: "testSuccess")
        
        ION.collection("test").page("page_001").outlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertFalse(result.isFailure)
            XCTAssertTrue(result.isSuccess)
            XCTAssertNotNil(result.optional())
            XCTAssertNotNil(result.value)
            XCTAssertNil(result.error)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testFailure() {
        let expectation = self.expectation(description: "testFailure")
        
        ION.collection("test").page("page_001").outlet("UnknownOutlet") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.outletNotFound(let name) = result.error! {
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
}
