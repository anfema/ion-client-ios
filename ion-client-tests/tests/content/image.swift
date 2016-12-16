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
import HashExtensions
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

            XCTAssert(url.absoluteString?.containsString("token=") ?? false)
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
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
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
    
    
    func testInvalidThumbnailOutlet() {
        let expectation = self.expectationWithDescription("testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").thumbnail("number", size: CGSize(width: 100, height: 100)) { result in
            
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
    
    
    func testWrongThumbnailOutlet() {
        let expectation = self.expectationWithDescription("testInvalidMediaDataOutlet")
        
        ION.collection("test").page("page_001").thumbnail("wrong", size: CGSize(width: 100, height: 100)) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail("wrong error thrown")
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    
    func testThumbnail() {
        let expectation = self.expectationWithDescription("testThumbnail")
        
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
            
            let maxSize = 100
            let size = CGSize(width: maxSize, height: maxSize)
            
            imageOutlet.thumbnail(size: size, callback: { result in
                guard case .Success(let imgRef) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let w = CGImageGetWidth(imgRef)
                let h = CGImageGetHeight(imgRef)
                
                XCTAssertTrue(max(w, h) == maxSize)
                
                ION.collection("test").page("page_001").thumbnail("image", size: size, callback: { result in
                    guard case .Success(let thumbnail) = result else {
                        XCTFail()
                        expectation.fulfill()
                        return
                    }
                    
                    let w2 = CGImageGetWidth(thumbnail)
                    let h2 = CGImageGetHeight(thumbnail)
                    
                    XCTAssertEqual(w, w2)
                    XCTAssertEqual(h, h2)
                    
                    XCTAssertTrue(max(w2, h2) == maxSize)
                })
            })
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testThumbnailTooBig() {
        let expectation = self.expectationWithDescription("testThumbnailTooBig")
        
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
            
            let maxSize = max(imageOutlet.originalSize.width * 2.0, imageOutlet.originalSize.height * 2.0)
            let size = CGSize(width: maxSize, height: maxSize)
            
            // Desired size is bigger than original image => thumbnail should not be bigger than the original image
            imageOutlet.thumbnail(size: size, callback: { result in
                guard case .Success(let imgRef) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let w = CGImageGetWidth(imgRef)
                let h = CGImageGetHeight(imgRef)
                
                XCTAssertTrue(w == Int(imageOutlet.originalSize.width))
                XCTAssertTrue(h == Int(imageOutlet.originalSize.height))
                
                ION.collection("test").page("page_001").thumbnail("image", size: size, callback: { result in
                    guard case .Success(let thumbnail) = result else {
                        XCTFail()
                        expectation.fulfill()
                        return
                    }
                    
                    let w2 = CGImageGetWidth(thumbnail)
                    let h2 = CGImageGetHeight(thumbnail)
                    
                    XCTAssertEqual(w, w2)
                    XCTAssertEqual(h, h2)
                    
                    XCTAssertTrue(w2 == Int(imageOutlet.originalSize.width))
                    XCTAssertTrue(h2 == Int(imageOutlet.originalSize.height))
                })
            })
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testMetadataThumbnailFail()
    {
        let expectation = self.expectationWithDescription("testMetadataThumbnail")
        ION.collection("test").metadata("page_001") { result in
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let metaPage) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let maxSize = 100
            let size = CGSize(width: maxSize, height: maxSize)
            
            // Thumbnail should only work for outlets named "thumbnail" or "icon"
            metaPage.thumbnail(size: size, callback: { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Failure(let error) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case .DidFail = error else {
                    XCTFail("wrong error thrown")
                    expectation.fulfill()
                    return
                }
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testChecksum() {
        let expectation = self.expectationWithDescription("testChecksum")
        
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
            
            
            imageOutlet.dataProvider({ result in
                guard case .Success(let dataProvider) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard let data: NSData = CGDataProviderCopyData(dataProvider) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let ckSum = imageOutlet.checksumMethod
                XCTAssert(ckSum == "sha256")
                
                XCTAssert(hashTypeFromName(ckSum) == .SHA256)
                XCTAssert(ckSum == imageOutlet.checksumMethod)
                XCTAssert(data.cryptoHash(hashTypeFromName(ckSum)).hexString() as String == imageOutlet.checksum)
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testOriginalChecksum() {
        let expectation = self.expectationWithDescription("testOriginalChecksum")
        
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
            
            
            imageOutlet.originalDataProvider({ result in
                guard case .Success(let dataProvider) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard let data: NSData = CGDataProviderCopyData(dataProvider) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let ckSum = imageOutlet.originalChecksumMethod
                XCTAssert(ckSum == "sha256")
                
                XCTAssert(hashTypeFromName(ckSum) == .SHA256)
                XCTAssert(ckSum == imageOutlet.originalChecksumMethod)
                XCTAssert(data.cryptoHash(hashTypeFromName(ckSum)).hexString() as String == imageOutlet.originalChecksum)
                
                expectation.fulfill()
            })
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}
