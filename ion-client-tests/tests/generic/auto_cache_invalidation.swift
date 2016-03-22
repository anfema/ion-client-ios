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
        let expectation = self.expectationWithDescription("testCollectionFetchNoTimeout")
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            ION.collection("test") { result in
                guard case .Success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionFetchWithTimeout() {
        let expectation = self.expectationWithDescription("testCollectionFetchWithTimeout")
        ION.config.cacheTimeout = 1
        ION.config.lastOnlineUpdate = [String:NSDate]()
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            sleep(2)
            ION.collection("test") { result in
                guard case .Success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        ION.config.cacheTimeout = 600
    }

    
    func testAutoPageUpdate() {
        guard self.mock == true else {
            return // only works with mocking enabled
        }
        
        var fail = false

        // set default mock bundle
        var path = NSBundle(forClass: self.dynamicType).resourcePath! + "/bundles/ion"
        do {
            try MockingBird.setMockBundle(path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }

        
        // clear cache
        ION.resetDiskCache()
        ION.resetMemCache()
        
        let expectation = self.expectationWithDescription("testAutoPageUpdate1")

        // seed cache
        ION.collection("test").download { success in
            XCTAssert(success == true)
            fail = true
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        if fail {
            return
        }
        let expectation2 = self.expectationWithDescription("testAutoPageUpdate2")
        
        // check page cache content
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                fail = true
                expectation2.fulfill()
                return
            }

            XCTAssert(page.layout == "layout-001")
            expectation2.fulfill()
        }

        self.waitForExpectationsWithTimeout(2.0, handler: nil)
        if fail {
            return
        }
        let expectation3 = self.expectationWithDescription("testAutoPageUpdate3")

        // reset online update so the next call fetches the collection again
        ION.config.lastOnlineUpdate = [String:NSDate]()
        

        // Switch to other mock bundle
        path = NSBundle(forClass: self.dynamicType).resourcePath! + "/bundles/ion_refresh"
        do {
            try MockingBird.setMockBundle(path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }
        
        // check if page has updated
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation3.fulfill()
                return
            }

            XCTAssert(page.layout == "new-layout-001")
            expectation3.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(10.0, handler: nil)
        
        // set default mock bundle
        path = NSBundle(forClass: self.dynamicType).resourcePath! + "/bundles/ion"
        do {
            try MockingBird.setMockBundle(path)
        } catch {
            XCTFail("Could not set up API mocking")
            return
        }
    }
    
}
