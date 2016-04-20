//
//  base.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import DEjson
@testable import ion_client

class contentBaseTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testOutletFetchSync() {
        let expectation = self.expectationWithDescription("testOutletFetchSync")
        
        ION.collection("test").page("page_001"){ result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success = page.outlet("text") {
                // all ok
            } else {
                XCTFail("outlet for name 'text' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testOutletFetchAsync")
        
        ION.collection("test").page("page_001").outlet("text") { result in
            guard case .Success = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testOutletFetchFail() {
        let expectation = self.expectationWithDescription("testOutletFetchFail")
        
        ION.collection("test").page("page_001").outlet("UnknownOutlet") { result in
            guard case .Success = result else {
                if case .OutletNotFound(let name) = result.error! {
                    XCTAssertEqual(name, "UnknownOutlet")
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testOutletArrayCount() {
        let expectation = self.expectationWithDescription("testOutletArrayCount")
        
        ION.collection("test").page("page_002").numberOfContentsForOutlet("colorarray") { count in
            XCTAssertEqual(count, 32)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testOutletArrayValues() {
        for i in 0..<32 {
            let expectation = self.expectationWithDescription("testOutletArrayValues")
            ION.collection("test").page("page_002").color("colorarray", position: i) { result in
                guard case .Success(let color) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                var r = CGFloat(0)
                var g = CGFloat(0)
                var b = CGFloat(0)
                var a = CGFloat(0)
                color.getRed(&r, green: &g, blue: &b, alpha: &a)
                XCTAssertEqual(r, CGFloat(Double(8 * i) / 255.0), "Item at position \(i) wrong red value")
                XCTAssertEqual(g, CGFloat(Double(8 * i) / 255.0), "Item at position \(i) wrong green value")
                XCTAssertEqual(b, CGFloat(Double(8 * i) / 255.0), "Item at position \(i) wrong blue value")
                XCTAssertEqual(a, 1.0, "Item at position \(i) wrong alpha value")
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    /// Test if the IONContent.factory throws the correct error when provided with the wrong JSONObject type.
    func testFactoryErrorWrongJSONObject() {
        do {
            try IONContent.factory(JSONObject.JSONString("dummyString"))
            XCTFail()
        } catch let err {
            guard case IONError.JSONObjectExpected(_) = err else {
                XCTFail()
                return
            }
        }
    }
    
    
    /// Test if the IONContent.factory throws the correct error when the provided JSONDictionary is missing the "type" key.
    func testFactoryErrorDictHasNoKeyType() {
        do {
            let jsonDict = ["dummyKey": JSONObject.JSONString("dummyValue")]
            try IONContent.factory(JSONObject.JSONDictionary(jsonDict))
            XCTFail()
        } catch let err {
            guard case IONError.InvalidJSON(_) = err else {
                XCTFail()
                return
            }
        }
    }
}