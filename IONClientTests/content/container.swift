//
//  container.swift
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

class containerContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testContainerOutletFetchSync() {
        let expectation = self.expectation(description: "testContainerOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let children) = page.children("container-001") {
                XCTAssertEqual(children.count, 2)
            } else {
                XCTFail("container content 'Container 001' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testContainerOutletFetchAsync() {
        let expectation = self.expectation(description: "testContainerOutletFetchAsync")
        
        ION.collection("test").page("page_001").children("container-001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let children) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(children.count, 2)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testContainerOutletSubscripting() {
        let expectation = self.expectation(description: "fetch outlet")
        
        ION.collection("test").page("page_001").outlet("container-001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case let container as IONContainerContent = outlet {
                XCTAssertEqual(container.children.count, 2)
                XCTAssertNotNil(container[0])
                XCTAssertNil(container[2])
            } else {
                XCTFail("container content 'Layout 001' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectation(description: "testOutletIncompatible")
        
        ION.collection("test").page("page_001").children("number") { result in
            
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
            
            guard case .failure(let error) = page.children("number") else {
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
        
        ION.collection("test").page("page_001").children("wrong") { result in
            
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
            
            guard case .failure(let error) = page.children("wrong") else {
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
        let json1: JSONObject = .jsonDictionary(["children": .jsonString("wrong")])
        
        do {
            _ = try IONContainerContent(json: json1)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .jsonArrayExpected(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
        
        
        // no "children" key
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONContainerContent(json: json2)
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
            
            guard case .jsonArrayExpected(let obj) = e else {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        } catch {
            XCTFail("wrong error thrown")
        }
    }
    
    
    func testJSONObjectExpected() {
        let json: JSONObject = .jsonString("children")
        
        do {
            _ = try IONContainerContent(json: json)
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
