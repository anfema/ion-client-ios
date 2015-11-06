//
//  file.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ampclient

class fileContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
       
    func testFileOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testFileOutletFetchAsync")
        
        AMP.collection("test").page("page_001").outlet("File") { outlet in

            AMP.collection("test").page("page_001").fileData("File") { data in
                guard case let file as AMPFileContent = outlet else {
                        XCTFail("File outlet not found or of wrong type \(outlet)")
                        expectation.fulfill()
                        return
                }
                XCTAssert(file.checksumMethod == "sha256")
                XCTAssert(data.cryptoHash(HashTypes(rawValue: file.checksumMethod)!).hexString() == file.checksum)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testFileOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("testFileOutletFetchAsyncCGImage")

        AMP.collection("test").page("page_001").outlet("File") { outlet in
            guard case let img as AMPFileContent = outlet else {
                XCTFail("File outlet not found or of wrong type \(outlet)")
                expectation.fulfill()
                return
            }
            if img.mimeType.hasPrefix("image/") {
                img.image() { image in
                    XCTAssertNotNil(image)
                    XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
                    expectation.fulfill()
                }
            } else {
                print("Skipping file image loading test as the file is not an image")
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}