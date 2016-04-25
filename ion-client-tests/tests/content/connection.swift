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
        let expectation = self.expectationWithDescription("testConnectionOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            if case .Success(let link) = page.link("connection") {
                XCTAssertEqual(link, NSURL(string: "ion://test/page_001#number"))
            } else {
                XCTFail("connection content 'Connection' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testConnectionOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testConnectionOutletFetchAsync")
        
        ION.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let link) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertEqual(link, NSURL(string: "ion://test/page_001#number"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testCollectionFetch() {
        let expectation = self.expectationWithDescription("testCollectionFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONCollection, IONError>) in
                guard  case .Success(let collection) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(collection)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testPageFetch() {
        let expectation = self.expectationWithDescription("testPageFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONPage, IONError>) in
                guard  case .Success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(page)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    
    func testOutletFetch() {
        let expectation = self.expectationWithDescription("testOutletFetch")
        
        ION.collection("test").page("page_001").link("connection") { result in
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            ION.resolve(url, callback: { (result: Result<IONContent, IONError>) in
                guard  case .Success(let outlet) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(outlet)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testMissingCollection() {
        let expectation = self.expectationWithDescription("testMissingCollection")
        
        let url = NSURL(string: "ion://")!
        ION.resolve(url) { (result: Result<IONCollection, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongCollection() {
        let expectation = self.expectationWithDescription("testWrongCollection")
        
        let url = NSURL(string: "ion://wrong")!
        ION.resolve(url) { (result: Result<IONCollection, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .CollectionNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testMissingPage() {
        let expectation = self.expectationWithDescription("testMissingPage")
        
        let url = NSURL(string: "ion://test/")!
        ION.resolve(url) { (result: Result<IONPage, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongPage() {
        let expectation = self.expectationWithDescription("testWrongPage")
        
        let url = NSURL(string: "ion://test/wrong")!
        ION.resolve(url) { (result: Result<IONPage, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .PageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testMissingOutlet() {
        let expectation = self.expectationWithDescription("testMissingOutlet")
        
        let url = NSURL(string: "ion://test/page_001/")!
        ION.resolve(url) { (result: Result<IONContent, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutlet() {
        let expectation = self.expectationWithDescription("testWrongOutlet")
        
        let url = NSURL(string: "ion://test/page_001/#wrong")!
        ION.resolve(url) { (result: Result<IONContent, IONError>) in
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
    
    
    func testWrongCollection2() {
        let expectation = self.expectationWithDescription("testWrongCollection2")
        
        let url = NSURL(string: "ion://wrong/page_001/#number")!
        ION.resolve(url) { (result: Result<IONContent, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .CollectionNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongPage2() {
        let expectation = self.expectationWithDescription("testWrongPage2")
        
        let url = NSURL(string: "ion://test/wrong/#number")!
        ION.resolve(url) { (result: Result<IONContent, IONError>) in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .PageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectationWithDescription("testOutletIncompatible")
        
        ION.collection("test").page("page_001").link("number") { result in
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
            
            guard case .Failure(let error) = page.link("number") else {
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
        
        ION.collection("test").page("page_001").link("wrong") { result in
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
            
            guard case .Failure(let error) = page.link("wrong") else {
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
        let json1: JSONObject = .JSONDictionary(["connection_string": .JSONNumber(0)])
        
        do {
            let _ = try IONConnectionContent(json: json1)
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
        
        
        // no "datetime" key
        let json2: JSONObject = .JSONDictionary(["test": .JSONString("test")])
        
        do {
            let _ = try IONConnectionContent(json: json2)
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
        let json: JSONObject = .JSONString("connection_string")
        
        do {
            let _ = try IONConnectionContent(json: json)
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