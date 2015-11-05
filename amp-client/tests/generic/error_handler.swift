//
//  error_handler.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ampclient

class errorHandlerTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPageFetchDuplicatedErrorhandler() {
        let expectation = self.expectationWithDescription("testPageFetchDuplicatedErrorhandler")
        
        AMP.collection("test").onError() { error in
            // this one should be overridden by the second one
            XCTFail()
            expectation.fulfill()
        }.onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
            
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchDuplicatedErrorhandler2() {
        let expectation = self.expectationWithDescription("testPageFetchDuplicatedErrorhandler2")
        var errorCount = 0
        
        AMP.collection("test").onError() { error in
            // this one should be overridden by the second one
            XCTFail()
        }.onError() { error in
            errorCount++
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            if errorCount == 2 {
                expectation.fulfill()
            }
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }.page("unknown_page2") { page in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        XCTAssertEqual(errorCount, 2)
    }

    func testPageFetchDuplicatedErrorhandler3() {
        let expectation = self.expectationWithDescription("testPageFetchDuplicatedErrorhandler3")
        
        AMP.collection("test").onError() { error in
            XCTFail()
            expectation.fulfill()
        }.page("page_001") { page in
        }

        AMP.collection("test").onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchDuplicatedErrorhandler4() {
        let expectation = self.expectationWithDescription("testPageFetchDuplicatedErrorhandler4 1")
        var expectFail = true
        
        AMP.collection("test").onError() { error in
            if !expectFail {
                XCTFail()
            }
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)

        let expectation2 = self.expectationWithDescription("testPageFetchDuplicatedErrorhandler4 2")
        expectFail = false

        AMP.collection("test").onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation2.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
//    func testBubblingToCollection() {
//        let expectation = self.expectationWithDescription("testBubblingToCollection")
//
//        AMP.collection("test").onError() { error in
//            if case .OutletNotFound = error {
//                // all ok, we expected this
//            } else {
//                XCTFail()
//            }
//            expectation.fulfill()
//        }.page("page_001").outlet("unknown_outlet") { outlet in
//            XCTFail()
//            expectation.fulfill()
//        }
//        
//        // Test fails because page callback did work (outlet callback does not retain error callback of collection)
//        
//        self.waitForExpectationsWithTimeout(1.0, handler: nil)
//    }
    
    func testBubblingToAMP() {
        let expectation = self.expectationWithDescription("testBubblingToAMP")
        
        AMP.config.errorHandler = { (collection, error) in
            if case .OutletNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("test").page("page_001").outlet("unknown_outlet") { outlet in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
}
