//
//  amp_clientTests.swift
//  amp-clientTests
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import XCTest
@testable import ampclient

class memcacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testCollectionMemcache() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            let collection2 = AMP.collection("test")
            XCTAssert(collection2 === collection)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }   
}
