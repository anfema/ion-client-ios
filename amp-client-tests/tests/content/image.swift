//
//  image.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import DEjson
@testable import amp_client

class imageContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImageOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        AMP.collection("test").page("page_001").image("image") { image in
            XCTAssertNotNil(image)
            XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testImageOutletFetchAsyncOriginalCGImage() {
        let expectation = self.expectationWithDescription("testImageOutletFetchAsyncCGImage")
        
        AMP.collection("test").page("page_001").originalImage("image") { image in
            XCTAssertNotNil(image)
            XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testImageOutletTempURL() {
        let expectation = self.expectationWithDescription("testImageOutletTempURL")
        
        AMP.collection("test").page("page_001").temporaryURL("image") { result in
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
    
    func testImageInitializerFail1() {
        let json: JSONObject = .JSONString("invalid")
        
        do {
            let image = try AMPImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as AMPError
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
    
    
    func testImageInitializerFail2() {
        let json: JSONObject = .JSONDictionary(["variation": .JSONString("@2x"), "outlet": .JSONString("titleImage")])
        
        do {
            let image = try AMPImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as AMPError
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
}