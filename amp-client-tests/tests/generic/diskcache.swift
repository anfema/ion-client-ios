//
//  diskcache.swift
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

class diskcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionDiskCache() {
        let expectation = self.expectationWithDescription("testCollectionDiskCache")
        AMP.resetMemCache()
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.resetMemCache()
            AMP.collection("test") { collection2 in
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2 !== collection)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionDiskCacheClean() {
        let expectation = self.expectationWithDescription("testCollectionDiskCacheClean")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test") { collection2 in
                XCTAssert(collection2 !== collection)
                XCTAssert(collection2 == collection)
                XCTAssertNotNil(collection2.lastUpdate)
                XCTAssert(collection2.lastUpdate!.compare(collection.lastUpdate!) == .OrderedDescending)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageDiskCache() {
        let expectation = self.expectationWithDescription("testPageDiskCache")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageDiskCacheClean() {
        let expectation = self.expectationWithDescription("testPageDiskCacheClean")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache()
            AMP.collection("test").page("page_001") { page2 in
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageDiskCacheLocaleClean() {
        let expectation = self.expectationWithDescription("testPageDiskCacheLocaleClean")
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            AMP.resetMemCache()
            AMP.resetDiskCache(locale: page.locale)
            AMP.collection("test").page("page_001") { page2 in
                XCTAssert(page2 !== page)
                XCTAssert(page2 == page)
                XCTAssertNotNil(page2.lastUpdate)
                XCTAssert(page2.lastUpdate!.compare(page.lastUpdate!) == .OrderedSame)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testDiskCacheForBinaryFilesMiss() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesMiss")
        AMP.resetMemCache()
        AMP.resetDiskCache()
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page.lastUpdate)
            if case let outlet as AMPImageContent = page.outlet("image") {
                let result = AMPRequest.fetchFromCache(outlet.imageURL!.absoluteString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
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
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testDiskCacheForBinaryFilesHit() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesHit")
        AMP.resetMemCache()
        AMP.resetDiskCache()
        AMP.collection("test").page("page_001").image("image") { image in
            XCTAssertNotNil(image)
            
            AMP.collection("test").page("page_001") { page in
                if case let outlet as AMPImageContent = page.outlet("image") {
                    let result = AMPRequest.fetchFromCache(outlet.imageURL!.absoluteString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
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
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testDiskCacheForBinaryFilesChange() {
        let expectation = self.expectationWithDescription("testDiskCacheForBinaryFilesChange")
        AMP.resetMemCache()
        AMP.resetDiskCache()
        AMP.collection("test").page("page_001") { page in
            if case let outlet as AMPImageContent = page.outlet("image") {
                outlet.image() { image in
                    XCTAssertNotNil(image)
                    
                    let urlString = outlet.imageURL!.absoluteString
                    
                    // find entry in cache db and change the checksum
                    var tmpDB = [JSONObject]()
                    for case .JSONDictionary(let dict) in AMPRequest.cacheDB! {
                        guard dict["url"] != nil,
                            case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                                tmpDB.append(.JSONDictionary(dict))
                                continue
                        }
                        
                        var changed = dict
                        changed["checksum"] = .JSONString("xxx")
                        tmpDB.append(.JSONDictionary(changed))
                    }
                    AMPRequest.cacheDB = tmpDB
                    AMPRequest.saveCacheDB()
                    
                    // now a cache lookup has to fail
                    let result = AMPRequest.fetchFromCache(urlString, checksumMethod: outlet.checksumMethod, checksum: outlet.checksum)
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
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}
