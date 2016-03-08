//
//  diskcache.swift
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

class diskcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionDiskCache() {
        let expectation = self.expectationWithDescription("testCollectionDiskCache")
        ION.resetMemCache()
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            ION.resetMemCache()
            ION.collection("test") { result in
                guard case .Success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2 !== collection)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testCollectionDiskCacheClean() {
        let expectation = self.expectationWithDescription("testCollectionDiskCacheClean")
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(collection.lastUpdate)
            ION.resetMemCache()
            ION.resetDiskCache()
            ION.collection("test") { result in
                guard case .Success(let collection2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(collection2 !== collection)
                XCTAssert(collection2 == collection)
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageDiskCache() {
        let expectation = self.expectationWithDescription("testPageDiskCache")
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page.lastUpdate)
            ION.resetMemCache()
            ION.collection("test").page("page_001") { result in
                guard case .Success(let page2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testPageDiskCacheClean() {
        let expectation = self.expectationWithDescription("testPageDiskCacheClean")
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page.lastUpdate)
            ION.resetMemCache()
            ION.resetDiskCache()
            ION.collection("test").page("page_001") { result in
                guard case .Success(let page2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageDiskCacheLocaleClean() {
        let expectation = self.expectationWithDescription("testPageDiskCacheLocaleClean")
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page.lastUpdate)
            ION.resetMemCache()
            ION.resetDiskCache(locale: page.locale)
            ION.collection("test").page("page_001") { result in
                guard case .Success(let page2) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testDiskCacheForBinaryFilesMiss() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesMiss")
        ION.resetMemCache()
        ION.resetDiskCache()
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page.lastUpdate)
            guard case .Success(let po) = page.outlet("image") else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            if case let outlet as IONImageContent = po {
                let result = IONRequest.fetchFromCache(outlet.imageURL!.absoluteString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
                XCTAssertNotNil(result)
                if case .Success(let filename) = result {
                    print(filename)
                    XCTFail("Cached image found when it should not be found")
                } else {
                    print("Cache miss!")
                }
            } else {
                XCTFail("Image outlet not found")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    func testDiskCacheForBinaryFilesHit() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesHit")
        ION.resetMemCache()
        ION.resetDiskCache()
        ION.collection("test").page("page_001").image("image") { result in
            XCTAssertNotNil(result)
            
            ION.collection("test").page("page_001") { result in
                guard case .Success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                guard case .Success(let po) = page.outlet("image") else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                if case let outlet as IONImageContent = po {
                    let result = IONRequest.fetchFromCache(outlet.imageURL!.absoluteString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
                    XCTAssertNotNil(result)
                    if case .Success(let filename) = result {
                        print(filename)
                    } else {
                        print("Cache miss!")
                        XCTFail("Cached image not found when it should be found")
                    }
                } else {
                    XCTFail("Image outlet not found")
                }
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testDiskCacheForBinaryFilesChange() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesChange")
        ION.resetMemCache()
        ION.resetDiskCache()
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .Success(let po) = page.outlet("image") else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case let outlet as IONImageContent = po {
                outlet.image() { image in
                    XCTAssertNotNil(image)
                    
                    let urlString = outlet.imageURL!.absoluteString
                    
                    // find entry in cache db and change the checksum
                    var tmpDB = [JSONObject]()
                    for case .JSONDictionary(let dict) in IONRequest.cacheDB! {
                        guard dict["url"] != nil,
                            case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                                tmpDB.append(.JSONDictionary(dict))
                                continue
                        }
                        
                        var changed = dict
                        changed["checksum"] = .JSONString("xxx")
                        tmpDB.append(.JSONDictionary(changed))
                    }
                    IONRequest.cacheDB = tmpDB
                    IONRequest.saveCacheDB()
                    
                    // now a cache lookup has to fail
                    let result = IONRequest.fetchFromCache(urlString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
                    XCTAssertNotNil(result)
                    if case .Success(let filename) = result {
                        print(filename)
                        XCTFail("Cached image found but checksum has changed, so a reload had to happen but didn't")
                    } else {
                        print("Cache miss!")
                    }
                    expectation.fulfill()
                }
            } else {
                XCTFail("Image outlet not found")
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

}
