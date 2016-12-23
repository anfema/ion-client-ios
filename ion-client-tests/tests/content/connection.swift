//
//  connection.swift
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

class connectionContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testConnectionOutletFetchSync() {
        let expectation = self.expectation(description: "testConnectionOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            if case .success(let link) = page.link("connection") {
                XCTAssertEqual(link, URL(string: "ion://test/page_001#number"))
            } else {
                XCTFail("connection content 'Connection' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testConnectionOutletFetchAsync() {
        let expectation = self.expectation(description: "testConnectionOutletFetchAsync")
        
        ION.collection("test").page("page_001").link("connection") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let link) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(link, URL(string: "ion://test/page_001#number"))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testCollectionFetch() {
        let expectation = self.expectation(description: "testCollectionFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONCollection>) in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard  case .success(let collection) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(collection)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testPageFetch() {
        let expectation = self.expectation(description: "testPageFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONPage>) in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard  case .success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(page)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    
    func testOutletFetch() {
        let expectation = self.expectation(description: "testOutletFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONContent>) in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard  case .success(let outlet) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(outlet)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testMissingCollection() {
        let expectation = self.expectation(description: "testMissingCollection")
        
        let url = URL(string: "ion://")!
        ION.resolve(url) { (result: Result<IONCollection>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.didFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongCollection() {
        let expectation = self.expectation(description: "testWrongCollection")
        
        let url = URL(string: "ion://wrong")!
        ION.resolve(url) { (result: Result<IONCollection>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.collectionNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testMissingPage() {
        let expectation = self.expectation(description: "testMissingPage")
        
        let url = URL(string: "ion://test/")!
        ION.resolve(url) { (result: Result<IONPage>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.didFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongPage() {
        let expectation = self.expectation(description: "testWrongPage")
        
        let url = URL(string: "ion://test/wrong")!
        ION.resolve(url) { (result: Result<IONPage>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.pageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testMissingOutlet() {
        let expectation = self.expectation(description: "testMissingOutlet")
        
        let url = URL(string: "ion://test/page_001/")!
        ION.resolve(url) { (result: Result<IONContent>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.didFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongOutlet() {
        let expectation = self.expectation(description: "testWrongOutlet")
        
        let url = URL(string: "ion://test/page_001/#wrong")!
        ION.resolve(url) { (result: Result<IONContent>) in
            
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
    
    
    func testWrongCollection2() {
        let expectation = self.expectation(description: "testWrongCollection2")
        
        let url = URL(string: "ion://wrong/page_001/#number")!
        ION.resolve(url) { (result: Result<IONContent>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.collectionNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongPage2() {
        let expectation = self.expectation(description: "testWrongPage2")
        
        let url = URL(string: "ion://test/wrong/#number")!
        ION.resolve(url) { (result: Result<IONContent>) in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.pageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectation(description: "testOutletIncompatible")
        
        ION.collection("test").page("page_001").link("number") { result in
            
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
            
            guard case .failure(let error) = page.link("number") else {
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
        
        ION.collection("test").page("page_001").link("wrong") { result in
            
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
            
            guard case .failure(let error) = page.link("wrong") else {
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
        let json1: JSONObject = .jsonDictionary(["connection_string": .jsonNumber(0)])
        
        do {
            _ = try IONConnectionContent(json: json1)
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
        
        
        // no "datetime" key
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONConnectionContent(json: json2)
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
        let json: JSONObject = .jsonString("connection_string")
        
        do {
            _ = try IONConnectionContent(json: json)
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
