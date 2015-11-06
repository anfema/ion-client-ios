//
//  page_metadata.swift
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

class pageMetadataTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMetadataFetchAsync() {
        let expectation = self.expectationWithDescription("testMetadataFetchAsync")
        AMP.resetMemCache()
        
        AMP.collection("test").metadata("page_001") { metadata in
            XCTAssert(metadata.identifier == "page_001")
            XCTAssert(metadata.layout == "Layout 001")
            XCTAssertNil(metadata.parent)
            XCTAssertNil(metadata.title)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataFetchAsync2() {
        let expectation = self.expectationWithDescription("testMetadataFetchAsync2")
        AMP.resetMemCache()
        
        AMP.collection("test").metadata("page_002") { metadata in
                XCTAssert(metadata.identifier == "page_002")
                XCTAssert(metadata.layout == "Layout 002")
                XCTAssertNil(metadata.parent)
                XCTAssert(metadata.title == "Donec ullamcorper")
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataEnumerateAsync() {
        let expectation = self.expectationWithDescription("testMetadataEnumerateAsync")
       
        var count = 0
        AMP.collection("test").enumerateMetadata(nil) { metadata in
            XCTAssertNil(metadata.parent)
            count++
            if count == 2 {
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        XCTAssert(count == 2)
    }

    func testMetadataEnumerateAsync2() {
        let expectation = self.expectationWithDescription("testMetadataEnumerateAsync2")
        
        AMP.collection("test").enumerateMetadata("page_002") { metadata in
            XCTAssert(metadata.parent == "page_002")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync() {
        let expectation = self.expectationWithDescription("testMetadataListAsync")
        
        AMP.collection("test").metadataList(nil) { list in
            XCTAssert(list.count == 2)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync2() {
        let expectation = self.expectationWithDescription("testMetadataListAsync2")
        
        AMP.collection("test").metadataList("page_002") { list in
            XCTAssert(list.count == 1)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataThumbnailAsync() {
        let expectation = self.expectationWithDescription("testMetadataThumbnailAsync")
        
        AMP.collection("test").metadata("page_002") { metadata in
            metadata.image { image in
                XCTAssertNotNil(image)
                XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}
