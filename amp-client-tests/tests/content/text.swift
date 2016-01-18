//
//  text.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import amp_client

class textContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTextOutletFetchSync() {
        let expectation = self.expectationWithDescription("testTextOutletFetchSync")
        
        AMP.collection("test").page("page_001") { page in
            if let text = page.text("text") {
                XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            } else {
                XCTFail("text content 'text' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testTextOutletFetchAsync() {
        let expectation = self.expectationWithDescription("testTextOutletFetchAsync")
        
        AMP.collection("test").page("page_001").text("text") { text in
            XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletHTMLAsync(){
        let expectation = self.expectationWithDescription("testTextOutletHTMLAsync")
        let outletName = "text"
        
        AMP.collection("test").page("page_001").text(outletName) { plainText in
            AMP.collection("test").page("page_001").html(outletName) { text in
                let prefix = "<div class=\"ampcontent ampcontent__\(outletName)\">"
                let suffix = "</div>"
                
                XCTAssertNotNil(text)
                XCTAssert(text.hasPrefix(prefix) == true)
                XCTAssert(text.hasSuffix(suffix) == true)
                
                var newString = text.substringToIndex(text.startIndex.advancedBy(text.characters.count - suffix.characters.count))
                newString = newString.substringFromIndex(text.startIndex.advancedBy(prefix.characters.count))
                newString = newString.stringByReplacingOccurrencesOfString("<br>", withString: "")
                
                XCTAssertEqual(plainText.characters.count, newString.characters.count)
                
                expectation.fulfill()
            }
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletHTMLSync(){
        let expectation = self.expectationWithDescription("testTextOutletHTMLSync")
        let outletName = "text"
        
        AMP.collection("test").page("page_001").text(outletName) { plainText in
            AMP.collection("test").page("page_001").waitUntilReady { page in
                guard let text = page.html(outletName, position: 0) else
                {
                    XCTFail()
                    return
                }
                
                let prefix = "<div class=\"ampcontent ampcontent__\(outletName)\">"
                let suffix = "</div>"
                
                XCTAssertNotNil(text)
                XCTAssert(text.hasPrefix(prefix) == true)
                XCTAssert(text.hasSuffix(suffix) == true)
                
                var newString = text.substringToIndex(text.startIndex.advancedBy(text.characters.count - suffix.characters.count))
                newString = newString.substringFromIndex(text.startIndex.advancedBy(prefix.characters.count))
                newString = newString.stringByReplacingOccurrencesOfString("<br>", withString: "")
                
                XCTAssertEqual(plainText.characters.count, newString.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletAttributedStringAsync(){
        let expectation = self.expectationWithDescription("testTextOutletAttributedStringAsync")
        let outletName = "text"
        
        AMP.collection("test").page("page_001").text(outletName) { plainText in
            AMP.collection("test").page("page_001").attributedString(outletName) { text in
                
                XCTAssertNotNil(text)
                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletAttributedStringSync(){
        let expectation = self.expectationWithDescription("testTextOutletAttributedStringSync")
        let outletName = "text"
        
        AMP.collection("test").page("page_001").text(outletName) { plainText in
            AMP.collection("test").page("page_001").waitUntilReady { page in
                guard let text = page.attributedString(outletName, position: 0) else
                {
                    XCTFail()
                    return
                }

                XCTAssertNotNil(text)
                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}