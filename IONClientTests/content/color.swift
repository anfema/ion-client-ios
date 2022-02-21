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
@testable import IONClient

class colorContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testColorOutletFetchSync() {
        let expectation = self.expectation(description: "testColorOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let value) = page.cachedColor("color") {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testColorOutletFetchSyncFail() {
        let expectation = self.expectation(description: "testColorOutletFetchSyncFail")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let value) = page.cachedColor("missing_color") {
                XCTFail("color content 'Color' returned \(value)")
            } else {
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testColorOutletFetchAsync() {
        let expectation = self.expectation(description: "testColorOutletFetchAsync")
        
        ION.collection("test").page("page_001").color("color") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let value) = result else {
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testColorOutletFetchAsyncFail() {
        let expectation = self.expectation(description: "testColorOutletFetchAsyncFail")
        
        ION.collection("test").page("page_001").color("missing_color") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.outletNotFound = result.error! {
                    // ok
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testColorInitializerSuccess() {
        let json: JSONObject = .jsonDictionary([
            "r": .jsonNumber(255),
            "g": .jsonNumber(100),
            "b": .jsonNumber(100),
            "a": .jsonNumber(255),
            "variation": .jsonString("@2x"),
            "outlet": .jsonString("color")])

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
        let json: JSONObject = .jsonDictionary([
            "r": .jsonNumber(255),
            "b": .jsonNumber(100),
            "a": .jsonNumber(255),
            "variation": .jsonString("@2x"),
            "outlet": .jsonString("color")])
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
    
    
    func testColorInitializerFail2() {
        let json: JSONObject = .jsonDictionary([
            "r": .jsonNumber(255),
            "g": .jsonNumber(100),
            "b": .jsonNumber(100),
            "a": .jsonNumber(255),
            "outlet": .jsonString("color")])
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
    
    
    func testColorInitializerFail3() {
        let json: JSONObject = .jsonString("invalid")
        
        do {
            let color = try IONColorContent(json: json)
            XCTFail("should have failed. returned \(color) instead")
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
        
        ION.collection("test").page("page_001").color("number") { result in
            
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
            
            guard case .failure(let error) = page.cachedColor("number") else {
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
        
        ION.collection("test").page("page_001").color("wrong") { result in
            
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
            
            guard case .failure(let error) = page.cachedColor("wrong") else {
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
