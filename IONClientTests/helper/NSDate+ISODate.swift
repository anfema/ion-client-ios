//
//  NSDate+ISODate.swift
//  ion-tests
//
//  Created by Dominik Felber on 13.01.16.
//  Copyright © 2016 anfema GmbH. All rights reserved.
//

import XCTest
@testable import IONClient

class NSDate_ISODate: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIsoDateString() {
        let date = Date(timeIntervalSince1970: 443795696)
        let isoString = date.toISODateString()
        XCTAssertTrue(isoString == "1984-01-24T12:34:56Z")
        
        if let newDate = Date.makeFrom(isoDateString: isoString) {
            XCTAssert(date.compare(newDate) == .orderedSame)
        } else {
            XCTFail("initializer 'isoDateString:' of NSDate returned nil")
        }
        
        let alternativeIsoString = "1984-01-24T12:34:56Z"
        if let newDate2 = Date.makeFrom(isoDateString: alternativeIsoString) {
            XCTAssert(date.compare(newDate2) == .orderedSame)
        } else {
            XCTFail("initializer 'isoDateString:' of NSDate returned nil")
        }
        
        let invalidIsoString = "1984-01-24T12:34:56.Z"
        if let newDate3 = Date.makeFrom(isoDateString: invalidIsoString) {
            XCTFail("initializer 'isoDateString:' of NSDate did not return \(newDate3) - but should fail")
        } else {
            // failed as intended
        }
    }
}
