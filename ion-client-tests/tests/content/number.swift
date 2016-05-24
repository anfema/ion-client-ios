//
//  number.swift
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

class numberContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNumberOutletFetchSync() {
        let expectation = self.expectationWithDescription("testNumberOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                return
            }

            if case .Success(let value) = page.number("number") {
                XCTAssertEqual(value, 123456.0)
            } else {
                XCTFail("number content 'Number' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testNumberOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testNumberOutletFetchAsync")
        
        ION.collection("test").page("page_001").number("number") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let value) = result else {
                XCTFail()
                return
            }

            XCTAssertEqual(value, 123456.0)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectationWithDescription("testOutletIncompatible")
        
        ION.collection("test").page("page_001").number("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testOutletIncompatibleSync() {
        let expectation = self.expectationWithDescription("testOutletIncompatibleSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .Failure(let error) = page.number("text") else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testInvalidOutlet() {
        let expectation = self.expectationWithDescription("testInvalidOutlet")
        
        ION.collection("test").page("page_001").number("wrong") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testInvalidOutletSync() {
        let expectation = self.expectationWithDescription("testInvalidOutletSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .Failure(let error) = page.number("wrong") else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .JSONDictionary(["value": .JSONString("wrong")])
        
        do {
            let _ = try IONNumberContent(json: json1)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .InvalidJSON(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
        
        
        // no "value" key
        let json2: JSONObject = .JSONDictionary(["test": .JSONString("test")])
        
        do {
            let _ = try IONNumberContent(json: json2)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .InvalidJSON(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
    }
    
    
    func testJSONObjectExpected() {
        let json: JSONObject = .JSONString("value")
        
        do {
            let _ = try IONNumberContent(json: json)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .JSONObjectExpected(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
    }
}