//
//  text.swift
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

class textContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTextOutletFetchSync() {
        let expectation = self.expectationWithDescription("testTextOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .Success(let text) = page.text("text") {
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
        
        ION.collection("test").page("page_001").text("text") { result in
            guard case .Success(let text) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletHTMLAsync(){
        let expectation = self.expectationWithDescription("testTextOutletHTMLAsync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            guard case .Success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").html(outletName) { result in
                guard case .Success(let text) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                let prefix = "<div class=\"ioncontent ioncontent__\(outletName)\">"
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
        
        ION.collection("test").page("page_001").text(outletName) { result in
            guard case .Success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").waitUntilReady { result in
                guard case .Success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case .Success(let text) = page.html(outletName, position: 0) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let prefix = "<div class=\"ioncontent ioncontent__\(outletName)\">"
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
        
        ION.collection("test").page("page_001").text(outletName) { result in
            guard case .Success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").attributedString(outletName) { result in
                guard case .Success(let text) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutletAttributedStringSync(){
        let expectation = self.expectationWithDescription("testTextOutletAttributedStringSync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            guard case .Success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").waitUntilReady { result in
                guard case .Success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case .Success(let text) = page.attributedString(outletName, position: 0) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertNotNil(text)
                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletText() {
        let expectation = self.expectationWithDescription("testWrongOutlet")
        
        ION.collection("test").page("page_001").text("number") { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletAttributedString() {
        let expectation = self.expectationWithDescription("testWrongOutletAttributedString")
        
        ION.collection("test").page("page_001").attributedString("number") { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletHTML() {
        let expectation = self.expectationWithDescription("testWrongOutletHTML")
        
        ION.collection("test").page("page_001").html("number") { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletText2() {
        let expectation = self.expectationWithDescription("testWrongOutlet2")
        
        ION.collection("test").page("page_001").text("number", position: 1) { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletAttributedString2() {
        let expectation = self.expectationWithDescription("testWrongOutletAttributedString2")
        
        ION.collection("test").page("page_001").attributedString("number", position: 1) { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletHTML2() {
        let expectation = self.expectationWithDescription("testWrongOutletHTML2")
        
        ION.collection("test").page("page_001").html("number", position: 1) { result in
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletSync() {
        let expectation = self.expectationWithDescription("testWrongOutletSync")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let htmlResult = page.html("number")
            
            guard case .Failure(let htmlError) = htmlResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = htmlError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let textResult = page.text("number")
            
            guard case .Failure(let textError) = textResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = textError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let attributedStringResult = page.attributedString("number")
            
            
            guard case .Failure(let attributedStringError) = attributedStringResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletIncompatible = attributedStringError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testWrongOutletSync2() {
        let expectation = self.expectationWithDescription("testWrongOutletSync2")
        
        ION.collection("test").page("page_001") { result in
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let htmlResult = page.html("number", position: 1)
            
            guard case .Failure(let htmlError) = htmlResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = htmlError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let textResult = page.text("number", position: 1)
            
            guard case .Failure(let textError) = textResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = textError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let attributedStringResult = page.attributedString("number", position: 1)
            
            
            guard case .Failure(let attributedStringError) = attributedStringResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .OutletNotFound = attributedStringError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testTextOutlet() {
        let expectation = self.expectationWithDescription("testTextOutlet")
        
        ION.collection("test").page("page_001").outlet("text") { result in
            guard case .Success(let outlet) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let textOutlet = outlet as? IONTextContent else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(textOutlet.plainText())
            XCTAssertNotNil(textOutlet.htmlText())
            XCTAssertNotNil(textOutlet.attributedString())
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}