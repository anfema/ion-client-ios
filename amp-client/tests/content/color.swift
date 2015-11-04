//
//  color.swift
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

class colorContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testColorOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.cachedColor("Color") {
                var r:CGFloat = 0.0
                var g:CGFloat = 0.0
                var b:CGFloat = 0.0
                var a:CGFloat = 0.0
                value.getRed(&r, green: &g, blue: &b, alpha: &a)
                XCTAssertEqual(r,   0.0 / 255.0)
                XCTAssertEqual(g,   0.0 / 255.0)
                XCTAssertEqual(b, 255.0 / 255.0)
                XCTAssertEqual(a, 255.0 / 255.0)
            } else {
                XCTFail("color content 'Color' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testColorOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").color("Color") { value in
            var r:CGFloat = 0.0
            var g:CGFloat = 0.0
            var b:CGFloat = 0.0
            var a:CGFloat = 0.0
            value.getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertEqual(r,   0.0 / 255.0)
            XCTAssertEqual(g,   0.0 / 255.0)
            XCTAssertEqual(b, 255.0 / 255.0)
            XCTAssertEqual(a, 255.0 / 255.0)

            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}