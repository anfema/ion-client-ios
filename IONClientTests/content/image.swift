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
import CryptoKit
@testable import IONClient

class imageContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImageOutletFetchAsyncCGImage() {
        let expectation = self.expectation(description: "testImageOutletFetchAsyncCGImage")
        
        ION.collection("test").page("page_001").image("image") { result in
            
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testImageOutletFetchAsyncOriginalCGImage() {
        let expectation = self.expectation(description: "testImageOutletFetchAsyncCGImage")
        
        ION.collection("test").page("page_001").originalImage("image") { result in
            
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testImageOutletTempURL() {
        let expectation = self.expectation(description: "testImageOutletTempURL")
        
        ION.collection("test").page("page_001").temporaryURL("image") { result in
            
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
    
    func testImageOutletAsync() {
        let expectation = self.expectation(description: "testImageOutletAsync")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
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
                guard case .success(let cgImage) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                XCTAssertNotNil(cgImage)
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    func testImageInitializerFail1() {
        let json: JSONObject = .jsonString("invalid")
        
        do {
            let image = try IONImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as IONError
        {
            XCTAssertNotNil(e)
            
            guard case .jsonObjectExpected(let obj) = e else {
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
        let json: JSONObject = .jsonDictionary(["variation": .jsonString("@2x"), "outlet": .jsonString("titleImage")])
        
        do {
            let image = try IONImageContent(json: json)
            XCTFail("should have failed. returned \(image) instead")
        }
            
        catch let e as IONError {
            XCTAssertNotNil(e)
    
            guard case .invalidJSON(let obj) = e else
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidTemporaryURLOutlet() {
        let expectation = self.expectation(description: "testInvalidTemporaryURLOutlet")
        
        ION.collection("test").page("page_001").temporaryURL("number") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = error else {
                XCTFail("wrong error thrown")
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
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testInvalidThumbnailOutlet() {
        let expectation = self.expectation(description: "testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").thumbnail("number", withSize: CGSize(width: 100, height: 100)) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = error else {
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testWrongThumbnailOutlet() {
        let expectation = self.expectation(description: "testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").thumbnail("wrong", withSize: CGSize(width: 100, height: 100)) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = error else {
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    
    func testThumbnail() {
        let expectation = self.expectation(description: "testThumbnail")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let imageOutlet = outlet as? IONImageContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let maxSize = 100
            let size = CGSize(width: maxSize, height: maxSize)
            
            imageOutlet.thumbnail(withSize: size, callback: { result in
                guard case .success(let imgRef) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let w = imgRef.width
                let h = imgRef.height
                
                XCTAssertTrue(max(w, h) == maxSize)
                
                ION.collection("test").page("page_001").thumbnail("image", withSize: size, callback: { result in
                    guard case .success(let thumbnail) = result else {
                        XCTFail()
                        expectation.fulfill()
                        return
                    }
                    
                    let w2 = thumbnail.width
                    let h2 = thumbnail.height
                    
                    XCTAssertEqual(w, w2)
                    XCTAssertEqual(h, h2)
                    
                    XCTAssertTrue(max(w2, h2) == maxSize)
                })
            })
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testThumbnailTooBig() {
        let expectation = self.expectation(description: "testThumbnailTooBig")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let imageOutlet = outlet as? IONImageContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let maxSize = max(imageOutlet.originalSize.width * 2.0, imageOutlet.originalSize.height * 2.0)
            let size = CGSize(width: maxSize, height: maxSize)
            
            // Desired size is bigger than original image => thumbnail should not be bigger than the original image
            imageOutlet.thumbnail(withSize: size, callback: { result in
                guard case .success(let imgRef) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let w = imgRef.width
                let h = imgRef.height
                
                XCTAssertTrue(w == Int(imageOutlet.originalSize.width))
                XCTAssertTrue(h == Int(imageOutlet.originalSize.height))
                
                ION.collection("test").page("page_001").thumbnail("image", withSize: size, callback: { result in
                    guard case .success(let thumbnail) = result else {
                        XCTFail()
                        expectation.fulfill()
                        return
                    }
                    
                    let w2 = thumbnail.width
                    let h2 = thumbnail.height
                    
                    XCTAssertEqual(w, w2)
                    XCTAssertEqual(h, h2)
                    
                    XCTAssertTrue(w2 == Int(imageOutlet.originalSize.width))
                    XCTAssertTrue(h2 == Int(imageOutlet.originalSize.height))
                })
            })
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testMetadataThumbnailFail()
    {
        let expectation = self.expectation(description: "testMetadataThumbnail")
        ION.collection("test").metadata("page_001") { result in
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let metaPage) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let maxSize = 100
            let size = CGSize(width: maxSize, height: maxSize)
            
            // Thumbnail should only work for outlets named "thumbnail" or "icon"
            metaPage.thumbnail(withSize: size, callback: { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .failure(let error) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case IONError.didFail = error else {
                    XCTFail("wrong error thrown")
                    expectation.fulfill()
                    return
                }
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testChecksum() {
        let expectation = self.expectation(description: "testChecksum")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let imageOutlet = outlet as? IONImageContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            imageOutlet.dataProvider({ result in
                guard case .success(let dataProvider) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard let data: NSData = dataProvider.data else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let ckSum = imageOutlet.checksumMethod
                XCTAssert(ckSum == "sha256")
                XCTAssert(ckSum == imageOutlet.checksumMethod)
                XCTAssert(SHA256.hash(data: data).hexString == imageOutlet.checksum)
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testOriginalChecksum() {
        let expectation = self.expectation(description: "testOriginalChecksum")
        
        ION.collection("test").page("page_001").outlet("image") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let imageOutlet = outlet as? IONImageContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            imageOutlet.originalDataProvider({ result in
                guard case .success(let dataProvider) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard let data: NSData = dataProvider.data else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let ckSum = imageOutlet.originalChecksumMethod
                XCTAssert(ckSum == "sha256")
                XCTAssert(ckSum == imageOutlet.originalChecksumMethod)
                XCTAssert(SHA256.hash(data: data).hexString == imageOutlet.originalChecksum)
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
}
