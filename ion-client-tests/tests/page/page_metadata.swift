//
//  page_metadata.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class pageMetadataTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMetadataFetchAsync() {
        let expectation = self.expectationWithDescription("testMetadataFetchAsync")
        ION.resetMemCache()
        
        ION.collection("test").metadata("page_001") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(metadata.identifier == "page_001")
            XCTAssert(metadata.layout == "layout-001")
            XCTAssertNil(metadata.parent)
            XCTAssertNotNil(metadata["text"])
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataFetchAsync2() {
        let expectation = self.expectationWithDescription("testMetadataFetchAsync2")
        ION.resetMemCache()
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(metadata.identifier == "page_002")
            XCTAssert(metadata.layout == "layout-002")
            XCTAssertNil(metadata.parent)
            XCTAssertNotNil(metadata["title"])
            XCTAssert(metadata["title"] == "Donec ullamcorper")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataEnumerateAsync() {
        let expectation = self.expectationWithDescription("testMetadataEnumerateAsync")
       
        var count = 0
        ION.collection("test").enumerateMetadata(nil) { metadata in
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
        
        ION.collection("test").enumerateMetadata("page_002") { metadata in
            XCTAssert(metadata.parent == "page_002")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync() {
        let expectation = self.expectationWithDescription("testMetadataListAsync")
        
        ION.collection("test").metadataList(nil) { list in
            if list.count == 2 {
                XCTAssert(list[0].position == 0)
                XCTAssert(list[0].identifier == "page_001")
                XCTAssert(list[1].position == 1)
                XCTAssert(list[1].identifier == "page_002")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync2() {
        let expectation = self.expectationWithDescription("testMetadataListAsync2")
        
        ION.collection("test").metadataList("page_002") { list in
            XCTAssert(list.count == 1)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataThumbnailAsync() {
        let expectation = self.expectationWithDescription("testMetadataThumbnailAsync")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            metadata.image { result in
                guard case .Success(let image) = result else {
                    XCTFail()
                    return
                }
                
                XCTAssertNotNil(image)
                let size = CGSize(width: 600, height: 400)
                XCTAssertEqual(size, image.size)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testMetaChildren() {
        let expectation = self.expectationWithDescription("testMetaChildren")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(metadata.children)
            if let children = metadata.children {
                XCTAssert(children.count == 1)
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    
    func testOriginalImage() {
        let expectation = self.expectationWithDescription("testOriginalImage")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(metadata.originalImageURL, nil)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testSubscriptSuccess1() {
        let expectation = self.expectationWithDescription("testSubscriptSuccess1")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(metadata["title"], "Donec ullamcorper")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testSubscriptSuccess2() {
        let expectation = self.expectationWithDescription("testSubscriptSuccess2")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let value = metadata["title", 0] else
            {
                XCTFail("did not return first element")
                return
            }
            
            XCTAssertEqual(value, "Donec ullamcorper")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testSubscriptFail1() {
        let expectation = self.expectationWithDescription("testSubscriptFail1")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssertNil(metadata["doesnotexist"])
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testSubscriptFail2() {
        let expectation = self.expectationWithDescription("testSubscriptFail2")
        
        ION.collection("test").metadata("page_002") { result in
            guard case .Success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssertNil(metadata["title", 1])
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}
