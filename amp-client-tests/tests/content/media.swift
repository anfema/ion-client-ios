//
//  media.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import HashExtensions
@testable import amp_client

class mediaContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMediaOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testMediaOutletFetchAsync")
        
        AMP.collection("test").page("page_001").outlet("media") { outlet in
            AMP.collection("test").page("page_001").mediaData("media") { data in
                guard case let file as AMPMediaContent = outlet else {
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
        
        AMP.collection("test").page("page_001").outlet("media") { outlet in
            guard case let mediaOutlet as AMPMediaContent = outlet else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssert(mediaOutlet.mimeType == "image/jpeg")
            
            mediaOutlet.image { image in
                XCTAssertNotNil(image)
                XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testMediaOutletURLFetchAsync() {
        let expectation = self.expectationWithDescription("testMediaOutletURLFetchAsync")
        
        AMP.collection("test").page("page_001").mediaURL("media") { url in
            XCTAssertNotNil(url)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testMediaOutletURLFetch() {
        let expectation = self.expectationWithDescription("testMediaOutletURLFetch")
        
        AMP.collection("test").page("page_001") { page in
            let mediaURL = page.mediaURL("media")
            XCTAssertNotNil(mediaURL)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testMediaOutletTempURL() {
        let expectation = self.expectationWithDescription("testMediaOutletTempURL")
        
        AMP.collection("test").page("page_001").temporaryURL("media") { url in
            XCTAssertNotNil(url)
            XCTAssert(url.absoluteString.containsString("token="))
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

}