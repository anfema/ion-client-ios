//
//  media.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import CryptoKit
@testable import IONClient

class mediaContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMediaOutletFetchAsync() {
        let expectation = self.expectation(description: "testMediaOutletFetchAsync")
        
        ION.collection("test").page("page_001").outlet("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").mediaData("media") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let data) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                guard case let file as IONMediaContent = outlet else {
                    XCTFail("Media outlet not found or of wrong type \(outlet)")
                    expectation.fulfill()
                    return
                }
                XCTAssert(file.checksumMethod == "sha256")
                XCTAssert(SHA256.hash(data: data).hexString == file.checksum)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testMediaOutletImageFetchAsync() {
        let expectation = self.expectation(description: "testMediaOutletImageFetchAsync")
        
        ION.collection("test").page("page_001").outlet("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case let mediaOutlet as IONMediaContent = outlet else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssert(mediaOutlet.mimeType == "image/jpeg")
            XCTAssertNotNil(mediaOutlet.imageURL)
            XCTAssertNotNil(mediaOutlet.originalImageURL)
            
            mediaOutlet.cachedURL({ result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let url) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            })
            
            mediaOutlet.image { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let image) = result else {
                    XCTFail()
                    return
                }
                
                XCTAssertNotNil(image)
                XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testMediaOutletURLFetchAsync() {
        let expectation = self.expectation(description: "testMediaOutletURLFetchAsync")
        
        ION.collection("test").page("page_001").mediaURL("media") { url in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssertNotNil(url)
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testMediaOutletURLFetch() {
        let expectation = self.expectation(description: "testMediaOutletURLFetch")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success = page.mediaURL("media") {
                // ok
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    
    func testMediaOutletTempURL() {
        let expectation = self.expectation(description: "testMediaOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(url.absoluteString.contains("token="))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidTempURLOutlet() {
        let expectation = self.expectation(description: "testInvalidTempURLOutlet")
        
        ION.collection("test").page("page_001").temporaryURL("number") { result in
            
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testCachedMediaURLOutlet() {
        let expectation = self.expectation(description: "testCachedMediaURLOutlet")
        
        ION.collection("test").page("page_001").cachedMediaURL("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    func testInvalidCachedMediaURLOutlet() {
        let expectation = self.expectation(description: "testInvalidCachedMediaURLOutlet")
        
        ION.collection("test").page("page_001").cachedMediaURL("number") { result in
            
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidMediaDataOutlet() {
        let expectation = self.expectation(description: "testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").mediaData("number") { result in
            
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidMediaURLOutlet() {
        let expectation = self.expectation(description: "testInvalidMediaURLOutlet")
        
        ION.collection("test").page("page_001").mediaURL("number") { result in
            
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
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .jsonDictionary(["name": .jsonNumber(0)])
        
        do {
            _ = try IONMediaContent(json: json1)
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
        
        
        // no "is_enabled" key
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONMediaContent(json: json2)
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
        let json: JSONObject = .jsonString("name")
        
        do {
            _ = try IONMediaContent(json: json)
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
