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
        
        AMP.collection("test").getSearchHandle { search in
            let items = search.search("ullamcorper")
            XCTAssert(items.count == 3)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionSearchExclusion() {
        let expectation = self.expectationWithDescription("testCollectionSearchExclusion")
        
        AMP.collection("test").getSearchHandle { search in
            let items = search.search("ullamcorper -nulla")
            XCTAssert(items.count == 1)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionStatement() {
        let expectation = self.expectationWithDescription("testCollectionStatement")
        
        AMP.collection("test").getSearchHandle { search in
            let items = search.search("donec duis")
            XCTAssert(items.count == 2)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionPhrase() {
        let expectation = self.expectationWithDescription("testCollectionPhrase")
        
        AMP.collection("test").getSearchHandle { search in
            let items = search.search("\"donec duis\"")
            XCTAssert(items.count == 0)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}

