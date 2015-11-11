//
//  keyvalue.swift
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

class keyValueContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testKVOutletFetchDictionarySync() {
        let expectation = self.expectationWithDescription("testKVOutletFetchDictionarySync")
        
        AMP.collection("test").page("page_001") { page in
            if let dict = page.keyValue("KeyValue") {
                XCTAssertNotNil(dict["foo"])
                XCTAssertNotNil(dict["wrzlpfrmpft"])
                XCTAssertNotNil(dict["glompf"])
            } else {
                XCTFail("kv content 'KeyValue' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testKVOutletFetchDictionaryAsync() {
        let expectation = self.expectationWithDescription("testKVOutletFetchDictionaryAsync")
        
        AMP.collection("test").page("page_001").keyValue("KeyValue") { dict in
            XCTAssertNotNil(dict["foo"])
            XCTAssertNotNil(dict["wrzlpfrmpft"])
            XCTAssertNotNil(dict["glompf"])
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testKVOutletFetchValueSync() {
        let expectation = self.expectationWithDescription("testKVOutletFetchValueSync")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.valueForKey("KeyValue", key: "foo") {
                XCTAssertEqual(value as? String, "bar")
            } else {
                XCTFail("kv content 'KeyValue' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testKVOutletFetchValueAsync() {
        let expectation = self.expectationWithDescription("testKVOutletFetchValueAsync")
        
        AMP.collection("test").page("page_001").valueForKey("KeyValue", key: "foo") { value in
            XCTAssertEqual(value as? String, "bar")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}