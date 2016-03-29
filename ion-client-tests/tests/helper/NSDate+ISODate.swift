//
//  NSDate+ISODate.swift
//  ion-tests
//
//  Created by Dominik Felber on 13.01.16.
//  Copyright © 2016 anfema GmbH. All rights reserved.
//

import XCTest
@testable import ion_client

class NSDate_ISODate: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testIsoDateString() {
        let date = NSDate(timeIntervalSince1970: 443795696)
        let isoDateString = date.isoDateString
        XCTAssertTrue(isoDateString == "1984-01-24T12:34:56Z")
        
        if let newDate = NSDate(isoDateString: isoDateString) {
            XCTAssert(date.compare(newDate) == .OrderedSame)
        } else {
            XCTFail("initializer 'isoDateString:' of NSDate returned nil")
        }
        
        let alternativeIsoDateString = "1984-01-24T12:34:56Z"
        if let newDate2 = NSDate(isoDateString: alternativeIsoDateString) {
            XCTAssert(date.compare(newDate2) == .OrderedSame)
        } else {
            XCTFail("initializer 'isoDateString:' of NSDate returned nil")
        }
        
        let invalidIsoDateString = "1984-01-24T12:34:56.Z"
        if let newDate3 = NSDate(isoDateString: invalidIsoDateString) {
            XCTFail("initializer 'isoDateString:' of NSDate did not return \(newDate3) - but should fail")
        } else {
            // failed as intended
        }
    }
}
