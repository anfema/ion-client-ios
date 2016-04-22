//
//  color.swift
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

class colorContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testColorOutletFetchSync() {
        let expectation = self.expectationWithDescription("testColorOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let value) = page.cachedColor("color") {
                var r:CGFloat = 0.0
                var g:CGFloat = 0.0
                var b:CGFloat = 0.0
                var a:CGFloat = 0.0
                value.getRed(&r, green: &g, blue: &b, alpha: &a)
                XCTAssertEqual(r,   0.0 / 255.0)
                XCTAssertEqual(g,   0.0 / 255.0)
                XCTAssertEqual(b, 255.0 / 255.0)
                XCTAssertEqual(a, 255.0 / 255.0)
            } else {
                XCTFail("color content 'Color' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testColorOutletFetchSyncFail() {
        let expectation = self.expectationWithDescription("testColorOutletFetchSyncFail")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let value) = page.cachedColor("missing_color") {
                XCTFail("color content 'Color' returned \(value)")
            } else {
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testColorOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testColorOutletFetchAsync")
        
        ION.collection("test").page("page_001").color("color") { result in
            guard case .Success(let value) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            var r:CGFloat = 0.0
            var g:CGFloat = 0.0
            var b:CGFloat = 0.0
            var a:CGFloat = 0.0
            value.getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertEqual(r,   0.0 / 255.0)
            XCTAssertEqual(g,   0.0 / 255.0)
            XCTAssertEqual(b, 255.0 / 255.0)
            XCTAssertEqual(a, 255.0 / 255.0)

            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testColorOutletFetchAsyncFail() {
        let expectation = self.expectationWithDescription("testColorOutletFetchAsyncFail")
        
        ION.collection("test").page("page_001").color("missing_color") { result in
            guard case .Success = result else {
                if case .OutletNotFound = result.error! {
                    // ok
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testColorInitializerSuccess() {
        let json: JSONObject = .JSONDictionary([
            "r": .JSONNumber(255),
            "g": .JSONNumber(100),
            "b": .JSONNumber(100),
            "a": .JSONNumber(255),
            "variation": .JSONString("@2x"),
            "outlet": .JSONString("color")])

        do {
            let color = try IONColorContent(json: json)
            XCTAssertNotNil(color)
        }
            
        catch let e
        {
            XCTFail("should have succeeded. returned \(e) instead")
        }
    }
    
    
    func testColorInitializerFail1() {
        let json: JSONObject = .JSONDictionary([
            "r": .JSONNumber(255),
            "b": .JSONNumber(100),
            "a": .JSONNumber(255),
            "variation": .JSONString("@2x"),
            "outlet": .JSONString("color")])
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
    
    
    func testColorInitializerFail2() {
        let json: JSONObject = .JSONDictionary([
            "r": .JSONNumber(255),
            "g": .JSONNumber(100),
            "b": .JSONNumber(100),
            "a": .JSONNumber(255),
            "outlet": .JSONString("color")])
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
    
    
    func testColorInitializerFail3() {
        let json: JSONObject = .JSONString("invalid")
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
        
        ION.collection("test").page("page_001").color("number") { result in
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
            
            guard case .Failure(let error) = page.cachedColor("number") else {
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
        
        ION.collection("test").page("page_001").color("wrong") { result in
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
            
            guard case .Failure(let error) = page.cachedColor("wrong") else {
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