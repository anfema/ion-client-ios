//
//  html5parserTests.swift
//  html5parserTests
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import XCTest
@testable import html5parser

class html5parserTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testText() {
        let tokens = HTML5Tokenizer(htmlString: "Text").tokenize()
        XCTAssert(tokens.count == 1)
        if case .Text(let data) = tokens[0] {
            XCTAssert(data == "Text")
        } else {
            XCTFail("Not a text token")
        }
    }

    func testTextWithNamedCharacter() {
        let tokens = HTML5Tokenizer(htmlString: "Text&amp;&uuml;").tokenize()
        XCTAssert(tokens.count == 1)
        if case .Text(let data) = tokens[0] {
            XCTAssert(data == "Text&ü")
        } else {
            XCTFail("Not a text token")
        }
    }

    func testTextWithHexCharacter() {
        let tokens = HTML5Tokenizer(htmlString: "Text&#x0020;").tokenize()
        XCTAssert(tokens.count == 1)
        if case .Text(let data) = tokens[0] {
            XCTAssert(data == "Text ")
        } else {
            XCTFail("Not a text token")
        }
    }

    func testTextWithNumberedCharacter() {
        let tokens = HTML5Tokenizer(htmlString: "Text&#32;").tokenize()
        XCTAssert(tokens.count == 1)
        if case .Text(let data) = tokens[0] {
            XCTAssert(data == "Text ")
        } else {
            XCTFail("Not a text token")
        }
    }
    
    
    func testSimpleHTML() {
        let tokens = HTML5Tokenizer(htmlString: "<strong>Text</strong>").tokenize()
        XCTAssert(tokens.count == 3)
        if case .StartTag(let name, let selfClosing, let attributes) = tokens[0] {
            XCTAssert(name == "strong")
            XCTAssert(selfClosing == false)
            XCTAssert(attributes == nil)
        } else {
            XCTFail("Not a start tag")
        }

        if case .Text(let data) = tokens[1] {
            XCTAssert(data == "Text")
        } else {
            XCTFail("Not a text node")
        }

        if case .EndTag(let name) = tokens[2] {
            XCTAssert(name == "strong")
        } else {
            XCTFail("Not an end tag")
        }
    }

    func testSelfClosing() {
        let tokens = HTML5Tokenizer(htmlString: "<br/>").tokenize()
        XCTAssert(tokens.count == 1)
        if case .StartTag(let name, let selfClosing, let attributes) = tokens[0] {
            XCTAssert(name == "br")
            XCTAssert(selfClosing == true)
            XCTAssert(attributes == nil)
        } else {
            XCTFail("Not a start tag")
        }
    }

    func testCapsulatedHTML() {
        let tokens = HTML5Tokenizer(htmlString: "<em><strong>Text</strong></em>").tokenize()
        XCTAssert(tokens.count == 5)
        if case .StartTag(let name, let selfClosing, let attributes) = tokens[0] {
            XCTAssert(name == "em")
            XCTAssert(selfClosing == false)
            XCTAssert(attributes == nil)
        } else {
            XCTFail("Not a start tag")
        }

        if case .StartTag(let name, let selfClosing, let attributes) = tokens[1] {
            XCTAssert(name == "strong")
            XCTAssert(selfClosing == false)
            XCTAssert(attributes == nil)
        } else {
            XCTFail("Not a start tag")
        }

        if case .Text(let data) = tokens[2] {
            XCTAssert(data == "Text")
        } else {
            XCTFail("Not a text node")
        }

        if case .EndTag(let name) = tokens[3] {
            XCTAssert(name == "strong")
        } else {
            XCTFail("Not an end tag")
        }

        if case .EndTag(let name) = tokens[4] {
            XCTAssert(name == "em")
        } else {
            XCTFail("Not an end tag")
        }
    }

}
