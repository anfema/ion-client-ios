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
import CryptoKit
@testable import IONClient

class fileContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
       
    func testFileOutletFetchAsync() {
        let expectation = self.expectation(description: "testFileOutletFetchAsync")
        
        ION.collection("test").page("page_001").outlet("file") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").fileData("file") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let data) = result else {
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
                XCTAssert(ckSum == file.checksumMethod)
                XCTAssert(SHA256.hash(data: data).hexString == file.checksum)
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testFileOutletFetchAsyncCGImage() {
        let expectation = self.expectation(description: "testFileOutletFetchAsyncCGImage")

        ION.collection("test").page("page_001").outlet("file") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
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
                    guard case .success(let image) = result else {
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testFileOutletTempURL() {
        let expectation = self.expectation(description: "testFileOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("file") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let url) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(url.absoluteString.contains("token="))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testFileDownloadProgress() {
        let expectation1 = self.expectation(description: "testFileDownloadProgress")
        let expectation2 = self.expectation(description: "testFileDownloadFinished")

        ION.resetDiskCache()
        
        // FIXME: Why is this called 2 times for 100%?
        var flag = false
        ION.config.progressHandler = { total, downloaded, count in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
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
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation2.fulfill()
                return
            }

            guard case let file as IONFileContent = outlet else {
                XCTFail("File outlet not found or of wrong type \(outlet)")
                return
            }
            file.data { result in
                guard case .success(let data) = result else {
                    XCTFail()
                    expectation2.fulfill()
                    return
                }

                XCTAssert(data.count == file.size)
                expectation2.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
        ION.config.progressHandler = nil
    }
    
    
    func testOutletIncompatible() {
        let expectation = self.expectation(description: "testOutletIncompatible")
        
        ION.collection("test").page("page_001").fileData("number") { result in
            
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
    
    
    func testInvalidOutlet() {
        let expectation = self.expectation(description: "testInvalidOutlet")
        
        ION.collection("test").page("page_001").fileData("wrong") { result in
            
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
        let json1: JSONObject = .jsonDictionary(["connection_string": .jsonNumber(0)])
        
        do {
            _ = try IONFileContent(json: json1)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case IONError.invalidJSON(let obj) = e else
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
        
        
        let json2: JSONObject = .jsonDictionary(["test": .jsonString("test")])
        
        do {
            _ = try IONFileContent(json: json2)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case IONError.invalidJSON(let obj) = e else
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
    
    
    func testJSONObjectExpected() {
        let json: JSONObject = .jsonString("connection_string")
        
        do {
            _ = try IONFileContent(json: json)
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .jsonObjectExpected(let obj) = e else
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
    
    
    func testFileOutletAsync() {
        let expectation = self.expectation(description: "testFileOutletAsync")
        
        ION.collection("test").page("page_001").outlet("file") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case let img as IONFileContent = outlet else {
                XCTFail("File outlet not found or of wrong type \(outlet)")
                expectation.fulfill()
                return
            }
            
            XCTAssertNil(img.originalImageURL)
            XCTAssertNil(img.imageURL)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
