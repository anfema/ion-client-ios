//
//  auto_cache_invalidation.swift
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
import anfema_mockingbird

class autoCacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionFetchNoTimeout() {
        let expectation = self.expectation(description: "testCollectionFetchNoTimeout")
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            ION.collection("test") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testCollectionFetchWithTimeout() {
        let expectation = self.expectation(description: "testCollectionFetchWithTimeout")
        ION.config.cacheTimeout = 1
        ION.config.lastOnlineUpdate = [String:Date]()
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            sleep(2)
            ION.collection("test") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectations(timeout: 5.0, handler: nil)
        ION.config.cacheTimeout = 600
    }

    
    func testAutoPageUpdate() {
        guard self.mock == true else {
            return // only works with mocking enabled
        }
        
        var fail = false

        // set default mock bundle
        var path = Bundle(for: type(of: self)).resourcePath! + "/bundles/ion"
        do {
            try MockingBird.setMockBundle(withPath: path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }

        
        // clear cache
        ION.resetDiskCache()
        ION.resetMemCache()
        
        let expectation = self.expectation(description: "testAutoPageUpdate1")

        // seed cache
        ION.collection("test").download { success in
            XCTAssert(success == true)
            fail = true
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10.0, handler: nil)
        if fail {
            return
        }
        let expectation2 = self.expectation(description: "testAutoPageUpdate2")
        
        // check page cache content
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                fail = true
                expectation2.fulfill()
                return
            }

            XCTAssert(page.layout == "layout-001")
            expectation2.fulfill()
        }

        self.waitForExpectations(timeout: 2.0, handler: nil)
        if fail {
            return
        }
        let expectation3 = self.expectation(description: "testAutoPageUpdate3")

        // reset online update so the next call fetches the collection again
        ION.config.lastOnlineUpdate = [String:Date]()
        

        // Switch to other mock bundle
        path = Bundle(for: type(of: self)).resourcePath! + "/bundles/ion_refresh"
        do {
            try MockingBird.setMockBundle(withPath: path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }
        
        // check if page has updated
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation3.fulfill()
                return
            }

            XCTAssert(page.layout == "new-layout-001")
            expectation3.fulfill()
        }
        
        self.waitForExpectations(timeout: 10.0, handler: nil)
        
        // set default mock bundle
        path = Bundle(for: type(of: self)).resourcePath! + "/bundles/ion"
        do {
            try MockingBird.setMockBundle(withPath: path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }
    }
    
}
