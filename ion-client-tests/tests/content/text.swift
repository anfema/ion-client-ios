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
        let expectation = self.expectation(description: "testTextOutletFetchSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            if case .success(let text) = page.text("text") {
                XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            } else {
                XCTFail("text content 'text' returned nil")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testTextOutletFetchAsync() {
        let expectation = self.expectation(description: "testTextOutletFetchAsync")
        
        ION.collection("test").page("page_001").text("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let text) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testTextOutletHTMLAsync(){
        let expectation = self.expectation(description: "testTextOutletHTMLAsync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").html(outletName) { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let text) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                let prefix = "<div class=\"ioncontent ioncontent__\(outletName)\">"
                let suffix = "</div>"
                
                XCTAssertNotNil(text)
                XCTAssert(text.hasPrefix(prefix) == true)
                XCTAssert(text.hasSuffix(suffix) == true)
                
                var newString = text.substring(to: text.index(text.startIndex, offsetBy: text.characters.count - suffix.characters.count))
                newString = newString.substring(from: text.index(text.startIndex, offsetBy: prefix.characters.count))
                newString = newString.replacingOccurrences(of: "<br>", with: "")
                
                XCTAssertEqual(plainText.characters.count, newString.characters.count)
                
                expectation.fulfill()
            }
        }

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testTextOutletHTMLSync(){
        let expectation = self.expectation(description: "testTextOutletHTMLSync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").waitUntilReady { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case .success(let text) = page.html(outletName, atPosition: 0) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                let prefix = "<div class=\"ioncontent ioncontent__\(outletName)\">"
                let suffix = "</div>"
                
                XCTAssertNotNil(text)
                XCTAssert(text.hasPrefix(prefix) == true)
                XCTAssert(text.hasSuffix(suffix) == true)
                
                var newString = text.substring(to: text.index(text.startIndex, offsetBy: text.characters.count - suffix.characters.count))
                newString = newString.substring(from: text.index(text.startIndex, offsetBy: prefix.characters.count))
                newString = newString.replacingOccurrences(of: "<br>", with: "")
                
                XCTAssertEqual(plainText.characters.count, newString.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testTextOutletAttributedStringAsync(){
        let expectation = self.expectation(description: "testTextOutletAttributedStringAsync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").attributedString(outletName) { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let text) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testTextOutletAttributedStringSync(){
        let expectation = self.expectation(description: "testTextOutletAttributedStringSync")
        let outletName = "text"
        
        ION.collection("test").page("page_001").text(outletName) { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let plainText) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            ION.collection("test").page("page_001").waitUntilReady { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                guard case .success(let text) = page.attributedString(outletName, atPosition: 0) else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                XCTAssertNotNil(text)
                XCTAssertEqual(plainText.characters.count, text.string.characters.count)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongOutletText() {
        let expectation = self.expectation(description: "testWrongOutlet")
        
        ION.collection("test").page("page_001").text("number") { result in
            
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
    
    
    func testWrongOutletAttributedString() {
        let expectation = self.expectation(description: "testWrongOutletAttributedString")
        
        ION.collection("test").page("page_001").attributedString("number") { result in
            
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
    
    
    func testWrongOutletHTML() {
        let expectation = self.expectation(description: "testWrongOutletHTML")
        
        ION.collection("test").page("page_001").html("number") { result in
            
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
    
    
    func testWrongOutletText2() {
        let expectation = self.expectation(description: "testWrongOutlet2")
        
        ION.collection("test").page("page_001").text("number", atPosition: 1) { result in
            
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
    
    
    func testWrongOutletAttributedString2() {
        let expectation = self.expectation(description: "testWrongOutletAttributedString2")
        
        ION.collection("test").page("page_001").attributedString("number", atPosition: 1) { result in
            
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
    
    
    func testWrongOutletHTML2() {
        let expectation = self.expectation(description: "testWrongOutletHTML2")
        
        ION.collection("test").page("page_001").html("number", atPosition: 1) { result in
            
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
    
    
    func testWrongOutletSync() {
        let expectation = self.expectation(description: "testWrongOutletSync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let htmlResult = page.html("number")
            
            guard case .failure(let htmlError) = htmlResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = htmlError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let textResult = page.text("number")
            
            guard case .failure(let textError) = textResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = textError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let attributedStringResult = page.attributedString("number")
            
            
            guard case .failure(let attributedStringError) = attributedStringResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletIncompatible = attributedStringError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testWrongOutletSync2() {
        let expectation = self.expectation(description: "testWrongOutletSync2")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            let htmlResult = page.html("number", atPosition: 1)
            
            guard case .failure(let htmlError) = htmlResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = htmlError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let textResult = page.text("number", atPosition: 1)
            
            guard case .failure(let textError) = textResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = textError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            
            let attributedStringResult = page.attributedString("number", atPosition: 1)
            
            
            guard case .failure(let attributedStringError) = attributedStringResult else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.outletNotFound = attributedStringError else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testTextOutlet() {
        let expectation = self.expectation(description: "testTextOutlet")
        
        ION.collection("test").page("page_001").outlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let outlet) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
}
