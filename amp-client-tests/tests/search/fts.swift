//
//  fts.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 12/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import amp_client

class ftsTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionSearch() {
        let expectation = self.expectationWithDescription("testCollectionSearch")
        
        AMP.collection("test").search("Smart*") { items in
            XCTAssertNotNil(items)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

