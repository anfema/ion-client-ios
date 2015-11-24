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
        let expectation = self.expectationWithDescription("testCollectionFetch")
        
        AMP.config.errorHandler = { collection, error in
            XCTFail()
            expectation.fulfill()
        }
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("testCollectionFetchError")
        
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
    
    func testCollectionMetaPath() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")

        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            collection.metaPath("subpage_001") { path in
                XCTAssert(path.count == 2)
                XCTAssert(path[0].identifier == "page_002")
                XCTAssert(path[1].identifier == "subpage_001")
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testCollectionMetaList() {
        let expectation = self.expectationWithDescription("testCollectionMetaPath")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            if let list = collection.metadataList(nil) {
                XCTAssert(list.count == 2)
                XCTAssert(list[0].identifier == "page_001")
                XCTAssert(list[1].identifier == "page_002")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testLeavesList() {
        let expectation = self.expectationWithDescription("testLeavesList")
        
        AMP.collection("test").leaves(nil) { pages in
            XCTAssert(pages.count == 2)
            XCTAssert(pages[0].identifier == "page_001")
            XCTAssert(pages[1].identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}

