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
@testable import IONClient

class pageMetadataTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMetadataFetchAsync() {
        let expectation = self.expectation(description: "testMetadataFetchAsync")
        ION.resetMemCache()
        
        ION.collection("test").metadata("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testMetadataFetchAsync2() {
        let expectation = self.expectation(description: "testMetadataFetchAsync2")
        ION.resetMemCache()
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }


    func testMetadataListAsync() {
        let expectation = self.expectation(description: "testMetadataListAsync")
        
        ION.collection("test").childMetadataList(forParent: nil) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let list) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testMetadataListAsync2() {
        let expectation = self.expectation(description: "testMetadataListAsync2")
        
        ION.collection("test").childMetadataList(forParent: "page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let list) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssert(list.count == 1)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testMetadataThumbnailAsync() {
        let expectation = self.expectation(description: "testMetadataThumbnailAsync")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            metadata.image { result in
                guard case .success(let image) = result else {
                    XCTFail()
                    return
                }
                
                XCTAssertNotNil(image)
                let size = CGSize(width: 600, height: 400)
                XCTAssertEqual(size, image.size)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testMetaChildren() {
        let expectation = self.expectation(description: "testMetaChildren")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    
    func testOriginalImage() {
        let expectation = self.expectation(description: "testOriginalImage")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(metadata.originalImageURL, nil)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testSubscriptSuccess1() {
        let expectation = self.expectation(description: "testSubscriptSuccess1")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(metadata["title"], "Donec ullamcorper")
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testSubscriptSuccess2() {
        let expectation = self.expectation(description: "testSubscriptSuccess2")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testSubscriptFail1() {
        let expectation = self.expectation(description: "testSubscriptFail1")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssertNil(metadata["doesnotexist"])
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testSubscriptFail2() {
        let expectation = self.expectation(description: "testSubscriptFail2")
        
        ION.collection("test").metadata("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssertNil(metadata["title", 1])
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testPageFromMetadata() {
        let expectation = self.expectation(description: "testPageFromMetadata")
        ION.resetMemCache()
        
        ION.collection("test").metadata("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            metadata.page({ result in
                guard case .success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertEqual(metadata.identifier, page.identifier)
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOriginalChecksum() {
        let expectation = self.expectation(description: "testOriginalChecksum")
        
        ION.collection("test").metadata("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metadata) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(metadata.originalChecksum)
            XCTAssertNotNil(metadata.originalChecksumMethod)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
}
