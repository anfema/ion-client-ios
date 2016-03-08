//
//  file.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
import HashExtensions
@testable import ion_client

class fileContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
       
    func testFileOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testFileOutletFetchAsync")
        
        ION.collection("test").page("page_001").outlet("file") { result in
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").fileData("file") { result in
                guard case .Success(let data) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                guard case let file as IONFileContent = outlet else {
                        XCTFail("File outlet not found or of wrong type \(outlet)")
                        expectation.fulfill()
                        return
                }
                // only works this way because of compiler bug (variable should be unneccessary)
                let ckSum = file.checksumMethod
                XCTAssert(ckSum == "sha256")
                
                XCTAssert(hashTypeFromName(ckSum) == .SHA256)
                XCTAssert(data.cryptoHash(hashTypeFromName(ckSum)).hexString() as String == file.checksum)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testFileOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("testFileOutletFetchAsyncCGImage")

        ION.collection("test").page("page_001").outlet("file") { result in
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case let img as IONFileContent = outlet else {
                XCTFail("File outlet not found or of wrong type \(outlet)")
                expectation.fulfill()
                return
            }
            if img.mimeType.hasPrefix("image/") {
                img.image() { result in
                    guard case .Success(let image) = result else {
                        XCTFail()
                        return
                    }
                    
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

    func testFileOutletTempURL() {
        let expectation = self.expectationWithDescription("testFileOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("file") { result in
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
    
    func testFileDownloadProgress() {
        if self.mock == true {
            return
        }
        let expectation1 = self.expectationWithDescription("testFileDownloadProgress")
        let expectation2 = self.expectationWithDescription("testFileDownloadFinished")

        ION.resetDiskCache()
        
        // FIXME: Why is this called 2 times for 100%?
        var flag = false
        ION.config.progressHandler = { total, downloaded, count in
            if count > 0 {
                XCTAssert(total > 0)
                let percent: Float = Float(downloaded) / Float(total) * 100.0
                print("Download progress \(percent)%")
            }
            
            if count == 0 && !flag {
                flag = true
                expectation1.fulfill()
            }
        }
        ION.collection("test").page("page_001").outlet("file") { result in
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation2.fulfill()
                return
            }

            guard case let file as IONFileContent = outlet else {
                XCTFail("File outlet not found or of wrong type \(outlet)")
                return
            }
            file.data { result in
                guard case .Success(let data) = result else {
                    XCTFail()
                    expectation2.fulfill()
                    return
                }

                XCTAssert(data.length == file.size)
                expectation2.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        ION.config.progressHandler = nil
    }
}