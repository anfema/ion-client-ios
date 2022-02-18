//
//  datetime.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import Foundation
@testable import IONClient

class datetimeContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
 
    
    func testDateOutletFetchSync() {
        let expectation = self.expectation(description: "testDateOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let value) = page.date("datetime") {
                XCTAssert(value.compare(Date(timeIntervalSince1970: 443795696)) == .orderedSame)
            } else {
                XCTFail("date content 'Datetime' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testDateOutletFetchAsync() {
        let expectation = self.expectation(description: "testDateOutletFetchAsync")
        
        ION.collection("test").page("page_001").date("datetime") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let value) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(value.compare(Date(timeIntervalSince1970: 443795696)) == .orderedSame)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .jsonDictionary(["datetime": .jsonNumber(0)])
        
        do {
            _ = try IONDateTimeContent(json: json1)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .invalidJSON(let obj) = e else
            {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        }
            
        catch
        {
            XCTFail("wrong error thrown")
        }
        
        
        // no "datetime" key
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONDateTimeContent(json: json2)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .invalidJSON(let obj) = e else
            {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        }
            
        catch
        {
            XCTFail("wrong error thrown")
        }
    }
    
    
    func testJSONObjectExpected() {
        let json: JSONObject = .jsonString("datetime")
        
        do {
            _ = try IONDateTimeContent(json: json)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .jsonObjectExpected(let obj) = e else
            {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        }
            
        catch
        {
            XCTFail("wrong error thrown")
        }
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectation(description: "testOutletIncompatible")
        
        ION.collection("test").page("page_001").date("number") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOutletIncompatibleSync() {
        let expectation = self.expectation(description: "testOutletIncompatibleSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .failure(let error) = page.date("number") else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testInvalidOutlet() {
        let expectation = self.expectation(description: "testInvalidOutlet")
        
        ION.collection("test").page("page_001").date("wrong") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testInvalidOutletSync() {
        let expectation = self.expectation(description: "testInvalidOutletSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .failure(let error) = page.date("wrong") else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
}
