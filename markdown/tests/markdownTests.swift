//
//  markdownTests.swift
//  markdownTests
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import XCTest
@testable import markdown

class markdownTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    // MARK: Blocks
    func testHeading() {
        let domNode = MDParser(markdown:"# Heading").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<h1>Heading</h1>")
    }

    func testHeadingAlternate() {
        let domNode = MDParser(markdown:"Heading\n###").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<h1>Heading</h1>")
    }

    func testSpaceIndentedCodeBlock() {
        let domNode = MDParser(markdown:"    I am code\n        and more code").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<pre><code class=\"lang-text\">I am code\n    and more code</code></pre>")
    }

    func testTabIndentedCodeBlock() {
        let domNode = MDParser(markdown:"\tI am code\n\t    and more code").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<pre><code class=\"lang-text\">I am code\n    and more code</code></pre>")
    }
    
    func testFencedCodeBlockTilde() {
        let domNode = MDParser(markdown:"~~~objc\n- (instancetype)init() {\n    self = super.init();\n    return self;\n}\n~~~").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<pre><code class=\"lang-objc\">- (instancetype)init() {\n    self = super.init();\n    return self;\n}\n</code></pre>")
    }

    func testFencedCodeBlockBacktick() {
        let domNode = MDParser(markdown:"```objc\n- (instancetype)init() {\n    self = super.init();\n    return self;\n}\n```").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<pre><code class=\"lang-objc\">- (instancetype)init() {\n    self = super.init();\n    return self;\n}\n</code></pre>")
    }

    func testQuoteBlock() {
        let domNode = MDParser(markdown:">\tQuote\n>\tand more text").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<blockquote>Quote\nand more text</blockquote>")
    }
    
    // MARK: Inlines
    func testBold() {
        let domNode = MDParser(markdown:"**bold**").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p><strong>bold</strong></p>")
    }
    
    func testItalic() {
        let domNode = MDParser(markdown:"*italic*").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p><em>italic</em></p>")
    }

    func testDeletedText() {
        let domNode = MDParser(markdown:"~~strike~~").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p><del>strike</del></p>")
    }

    func testInlineCode() {
        let domNode = MDParser(markdown:"Bla `fasel` blubb").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p>Bla <code>fasel</code> blubb</p>")
    }

    func testLinkAnker() {
        let domNode = MDParser(markdown:"Bla [fasel](#anker) blubb").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p>Bla <a href=\"#anker\">fasel</a> blubb</p>")
    }

    func testLinkExternal() {
        let domNode = MDParser(markdown:"Bla [fasel](http://anker) blubb").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p>Bla <a href=\"http://anker\">fasel</a> blubb</p>")
    }

    func testImage() {
        let domNode = MDParser(markdown:"Bla ![fasel](http://anker) blubb").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<p>Bla <img src=\"http://anker\" alt=\"fasel\"> blubb</p>")
    }

    // MARK: Unordered lists
    func testSimpleList() {
        let domNode = MDParser(markdown:"- List item 1\n- List item 2\n- List item 3").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ul>\n<li>List item 1</li>\n<li>List item 2</li>\n<li>List item 3</li>\n</ul>")
    }

    func testMultilineSimpleList() {
        let domNode = MDParser(markdown:"- List item 1\n  Hello\n- List item 2\n- List item 3\n Hello").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ul>\n<li>\n<p>List item 1\nHello</p>\n</li>\n<li>List item 2</li>\n<li>\n<p>List item 3\nHello</p>\n</li>\n</ul>")
    }

    func testCascadedList() {
        let domNode = MDParser(markdown:"- List item 1\n    - Level 2 item 1\n    - Level 2 item 2\n- List item 2\n- List item 3").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ul>\n<li>\n<p>List item 1</p>\n\n<ul>\n<li>Level 2 item 1</li>\n<li>Level 2 item 2</li>\n</ul>\n</li>\n<li>List item 2</li>\n<li>List item 3</li>\n</ul>")
    }

    // MARK: Ordered lists
    func testOrderedList() {
        let domNode = MDParser(markdown:"1. List item 1\n100. List item 2\n1. List item 3").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ol>\n<li>List item 1</li>\n<li>List item 2</li>\n<li>List item 3</li>\n</ol>")
    }
    
    func testMultilineOrderedList() {
        let domNode = MDParser(markdown:"1. List item 1\n  Hello\n2. List item 2\n3. List item 3\n Hello").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ol>\n<li>\n<p>List item 1\nHello</p>\n</li>\n<li>List item 2</li>\n<li>\n<p>List item 3\nHello</p>\n</li>\n</ol>")
    }
    
    func testCascadedOrderedList() {
        let domNode = MDParser(markdown:"1. List item 1\n    a) Level 2 item 1\n    b) Level 2 item 2\n2. List item 2\n3. List item 3").render()
        print(domNode.debugDescription)
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ol>\n<li>\n<p>List item 1</p>\n\n<ol>\n<li>Level 2 item 1</li>\n<li>Level 2 item 2</li>\n</ol>\n</li>\n<li>List item 2</li>\n<li>List item 3</li>\n</ol>")
    }

    // MARK: Complex

    func testCascadedComplexList() {
        let domNode = MDParser(markdown:"1. List __item__ 1\n    - Level 2 `item` 1\n    - Level 2 item 2\n2. *List* item 2\n3. List item 3").render()
        print(domNode.debugDescription)
        print(domNode.renderAttributedString(AttributedStringStyling()))
        XCTAssertEqual(domNode.renderHTMLFragment(), "<ol>\n<li>\n<p>List <strong>item</strong> 1</p>\n\n<ul>\n<li>Level 2 <code>item</code> 1</li>\n<li>Level 2 item 2</li>\n</ul>\n</li>\n<li><em>List</em> item 2</li>\n<li>List item 3</li>\n</ol>")
    }
}
