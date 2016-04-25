//
//  fts.swift
//  ion-tests
//
//  Created by Johannes Schriewer on 12/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class ftsTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
        ION.config.enableFTS("test")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionSearch() {
        let expectation = self.expectationWithDescription("testCollectionSearch")
        
        ION.collection("test").getSearchHandle { result in
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("ullamcorper")
            XCTAssert(items.count == 4)
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testCollectionSearchExclusion() {
        let expectation = self.expectationWithDescription("testCollectionSearchExclusion")
        
        ION.collection("test").getSearchHandle { result in
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("ullamcorper -nulla")
            XCTAssert(items.count == 1)
            
            guard let item = items.first else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(item.html(), "<p>Donec <strong>ullamcorper</strong></p>")
            XCTAssertEqual(item.attributedString().string, "Donec ullamcorper\n\n")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testCollectionStatement() {
        let expectation = self.expectationWithDescription("testCollectionStatement")
        
        ION.collection("test").getSearchHandle { result in
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("donec duis")
            XCTAssert(items.count == 3)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testCollectionPhrase() {
        let expectation = self.expectationWithDescription("testCollectionPhrase")
        
        ION.collection("test").getSearchHandle { result in
            guard case .Success(let search) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let items = search.search("\"donec duis\"")
            XCTAssert(items.count == 0)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    func testDownloadFTS()
    {
        // TODO: Test somehow that IONFTSDBDidUpdateNotification was sent.
        
        let expectation = self.expectationWithDescription("testDownloadFTS")
        
        ION.config.enableFTS("test")
        XCTAssertTrue(ION.config.isFTSEnabled("test"))
        
        ION.downloadFTSDB("test") {
            // TODO: Test if download was successful
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testEnableDisableSearchHandle()
    {
        ION.config.enableFTS("test")
        XCTAssertTrue(ION.config.isFTSEnabled("test"))
        
        ION.config.disableFTS("test")
        XCTAssertFalse(ION.config.isFTSEnabled("test"))
    }
    
    
    func testGetSearchHandle()
    {
        let expectation = self.expectationWithDescription("testGetSearchHandle")
        
        ION.config.disableFTS("test")
        XCTAssertFalse(ION.config.isFTSEnabled("test"))
        
        ION.collection("test").getSearchHandle { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}

