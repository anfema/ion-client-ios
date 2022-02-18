//
//  option.swift
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

class optionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testOptionOutletFetchSync() {
        let expectation = self.expectation(description: "testOptionOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let value) = page.selectedOption("option") {
                XCTAssertEqual(value, "2")
            } else {
                XCTFail("option content 'Option' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOptionOutletFetchAsync() {
        let expectation = self.expectation(description: "testOptionOutletFetchAsync")
        
        ION.collection("test").page("page_001").selectedOption("option") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let value) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(value, "2")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    
    func testOutletIncompatible() {
        let expectation = self.expectation(description: "testOutletIncompatible")
        
        ION.collection("test").page("page_001").selectedOption("number") { result in
            
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
            
            guard case .failure(let error) = page.selectedOption("number") else {
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
        
        ION.collection("test").page("page_001").selectedOption("wrong") { result in
            
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
            
            guard case .failure(let error) = page.selectedOption("wrong") else {
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
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .jsonDictionary(["value": .jsonNumber(0.0)])
        
        do {
            _ = try IONOptionContent(json: json1)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case IONError.invalidJSON(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
        
        
        // no "value" key
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONOptionContent(json: json2)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case IONError.invalidJSON(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
    }
    
    
    func testJSONObjectExpected() {
        let json: JSONObject = .jsonString("value")
        
        do {
            _ = try IONOptionContent(json: json)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .jsonObjectExpected(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
    }
}
