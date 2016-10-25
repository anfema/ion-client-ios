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
import DEjson
import HashExtensions
@testable import ion_client

class mediaContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMediaOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testMediaOutletFetchAsync")
        
        ION.collection("test").page("page_001").outlet("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").mediaData("media") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(let data) = result else {
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
                XCTAssert(data.cryptoHash(hashTypeFromName(file.checksumMethod)).hexString() == file.checksum)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testMediaOutletImageFetchAsync() {
        let expectation = self.expectationWithDescription("testMediaOutletImageFetchAsync")
        
        ION.collection("test").page("page_001").outlet("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let outlet) = result else {
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
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(let url) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard let path = url.path else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(path))
            })
            
            mediaOutlet.image { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(let image) = result else {
                    XCTFail()
                    return
                }
                
                XCTAssertNotNil(image)
                XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testMediaOutletURLFetchAsync() {
        let expectation = self.expectationWithDescription("testMediaOutletURLFetchAsync")
        
        ION.collection("test").page("page_001").mediaURL("media") { url in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            XCTAssertNotNil(url)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testMediaOutletURLFetch() {
        let expectation = self.expectationWithDescription("testMediaOutletURLFetch")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success = page.mediaURL("media") {
                // ok
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    
    func testMediaOutletTempURL() {
        let expectation = self.expectationWithDescription("testMediaOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertTrue(url.absoluteString?.containsString("token=") ?? false)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testInvalidTempURLOutlet() {
        let expectation = self.expectationWithDescription("testInvalidTempURLOutlet")
        
        ION.collection("test").page("page_001").temporaryURL("number") { result in
            
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
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testCachedMediaURLOutlet() {
        let expectation = self.expectationWithDescription("testCachedMediaURLOutlet")
        
        ION.collection("test").page("page_001").cachedMediaURL("media") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let path = url.path else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertTrue(NSFileManager.defaultManager().fileExistsAtPath(path))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    func testInvalidCachedMediaURLOutlet() {
        let expectation = self.expectationWithDescription("testInvalidCachedMediaURLOutlet")
        
        ION.collection("test").page("page_001").cachedMediaURL("number") { result in
            
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
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testInvalidMediaDataOutlet() {
        let expectation = self.expectationWithDescription("testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").mediaData("number") { result in
            
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
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testInvalidMediaURLOutlet() {
        let expectation = self.expectationWithDescription("testInvalidMediaURLOutlet")
        
        ION.collection("test").page("page_001").mediaURL("number") { result in
            
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
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testInvalidJSON() {
        // invalid value for correct key
        let json1: JSONObject = .JSONDictionary(["name": .JSONNumber(0)])
        
        do {
            let _ = try IONMediaContent(json: json1)
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
        
        
        // no "is_enabled" key
        let json2: JSONObject = .JSONDictionary(["test": .JSONString("test")])
        
        do {
            let _ = try IONMediaContent(json: json2)
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
        let json: JSONObject = .JSONString("name")
        
        do {
            let _ = try IONMediaContent(json: json)
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
