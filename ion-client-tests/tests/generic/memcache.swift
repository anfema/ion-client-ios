//
//  memcache.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class memcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionMemcache() {
        let expectation = self.expectationWithDescription("testCollectionMemcache")
        
        ION.collection("test") { result in
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            let collection2 = ION.collection("test")
            XCTAssert(collection2 === collection)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }   
}
