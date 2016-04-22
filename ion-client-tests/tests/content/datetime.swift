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
import DEjson
@testable import ion_client

class datetimeContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
 
    
    func testDateOutletFetchSync() {
        let expectation = self.expectationWithDescription("testDateOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let value) = page.date("datetime") {
                XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            } else {
                XCTFail("date content 'Datetime' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testDateOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testDateOutletFetchAsync")
        
        ION.collection("test").page("page_001").date("datetime") { result in
            guard case .Success(let value) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .JSONDictionary(["datetime": .JSONNumber(0)])
        
        do {
            let _ = try IONDateTimeContent(json: json1)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .InvalidJSON(let obj) = e else
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
        let json2: JSONObject = .JSONDictionary(["test": .JSONString("test")])
        
        do {
            let _ = try IONDateTimeContent(json: json2)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .InvalidJSON(let obj) = e else
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
        let json: JSONObject = .JSONString("datetime")
        
        do {
            let image = try IONDateTimeContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .JSONObjectExpected(let obj) = e else
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
        let expectation = self.expectationWithDescription("testOutletIncompatible")
        
        ION.collection("test").page("page_001").date("number") { result in
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
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .Failure(let error) = page.date("number") else {
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
        
        ION.collection("test").page("page_001").date("wrong") { result in
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
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .Failure(let error) = page.date("wrong") else {
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
}