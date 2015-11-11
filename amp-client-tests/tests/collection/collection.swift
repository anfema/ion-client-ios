//
//  collection.swift
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

class collectionTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCollectionFetch() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }.onError({ error in
            XCTFail()
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.config.errorHandler = { (collectionID, error) in
            XCTAssertEqual(collectionID, "gnarf")
            if case .CollectionNotFound(let name) = error {
                XCTAssertEqual(name, "gnarf")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("gnarf") { collection in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
}

