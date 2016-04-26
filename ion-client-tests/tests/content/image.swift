//
//  image.swift
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

class imageContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImageOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        ION.collection("test").page("page_001").image("image") { result in
            
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
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testImageOutletFetchAsyncOriginalCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        ION.collection("test").page("page_001").originalImage("image") { result in
            
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
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testImageOutletTempURL() {
        let expectation = self.expectationWithDescription("testImageOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(url.absoluteString.containsString("token="))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testImageOutletAsync() {
        let expectation = self.expectationWithDescription("testImageOutletAsync")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let imageOutlet = outlet as? IONImageContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(imageOutlet.originalURL)
            XCTAssertNotNil(imageOutlet.originalImageURL)
            
            XCTAssert(imageOutlet.originalChecksumMethod == "sha256")
            XCTAssert(imageOutlet.originalChecksum == "d8b358afb51ed64c2a9abdaf874b1cd0ab35dd20744b84d502ba3172b49ddc56")
            
            imageOutlet.originalCGImage({ result in
                guard case .Success(let cgImage) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(cgImage)
            })
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testImageInitializerFail1() {
        let json: JSONObject = .JSONString("invalid")
        
        do {
            let image = try IONImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .JSONObjectExpected(let obj) = e else {
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
    
    
    func testImageInitializerFail2() {
        let json: JSONObject = .JSONDictionary(["variation": .JSONString("@2x"), "outlet": .JSONString("titleImage")])
        
        do {
            let image = try IONImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
    
            guard case .InvalidJSON(let obj) = e else
            {
                XCTFail("wrong error thrown")
                return
            }
            
            XCTAssertNotNil(obj)
        }
            
        catch {
            XCTFail("wrong error thrown")
        }
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testInvalidTemporaryURLOutlet() {
        let expectation = self.expectationWithDescription("testInvalidTemporaryURLOutlet")
        
        ION.collection("test").page("page_001").temporaryURL("number") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail("wrong error thrown")
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}