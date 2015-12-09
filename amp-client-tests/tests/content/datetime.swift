//
//  datetime.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import Foundation
@testable import amp_client

class datetimeContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
 
    
    func testDateOutletFetchSync() {
        let expectation = self.expectationWithDescription("testDateOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.date("datetime") {
                XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            } else {
                XCTFail("date content 'Datetime' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testDateOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testDateOutletFetchAsync")
        
        AMP.collection("test").page("page_001").date("datetime") { value in
            XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}