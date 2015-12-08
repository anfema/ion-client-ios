//
//  image.swift
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

class imageContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImageOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        AMP.collection("test").page("page_001").image("image") { image in
            XCTAssertNotNil(image)
            XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testImageOutletFetchAsyncOriginalCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        AMP.collection("test").page("page_001").originalImage("image") { image in
            XCTAssertNotNil(image)
            XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}