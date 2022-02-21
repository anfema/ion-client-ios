//
//  tokenizer.swift
//  html5tokenizer
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

open class HTML5Tokenizer {
    /// The HTML to tokenize
    fileprivate let html: String

    /// Temporary buffer to accumulate Strings in
    fileprivate var tempBuffer: String
    fileprivate var charBuffer: String
    fileprivate var tempTagname: String
    fileprivate var tempAttributeName: String
    fileprivate var tempAttributes: [String: String]?

    /// current state machine state
    fileprivate var state: TokenizerState = .data
    fileprivate var stateStack = [TokenizerState]()

    fileprivate var charRefState: CharRefState = .namedChar

    public init(htmlString: String) {
        self.html = htmlString
        self.tempBuffer = ""
        self.charBuffer = ""
        self.tempTagname = ""
        self.tempAttributeName = ""
    }

    open func tokenize() -> [HTML5Token] {
        var result = [HTML5Token]()
        var generator = self.html.unicodeScalars.makeIterator()
        self.state = .data

        while let c = generator.next() {
            if let token = self.consume(c, generator: &generator) {
                result.append(token)
            }
        }

        if self.state == .data && self.tempBuffer.isEmpty == false {
            result.append(.text(data: self.tempBuffer))
            self.tempBuffer = ""
        }

        return result
    }

    @discardableResult fileprivate func consume(_ c: UnicodeScalar, generator: inout String.UnicodeScalarView.Iterator) -> HTML5Token? {

        switch self.state {

        case .data:
            return self.parseData(c)

        case .characterReference:
            if let char = self.parseCharRef(c) {
                self.tempBuffer.append(String(char))
            }

        case .tagOpen:
            return self.parseTagOpen(c)

        case .endTagOpen:
            return self.parseEndTagOpen(c)

        case .tagName:
            return self.parseTagName(c)

        case .selfClosingStartTag:
            return self.parseSelfClosingStartTag(c, generator: &generator)

        case .attributeNameBefore:
            return self.parseAttributeNameBefore(c)

        case .attributeName:
            return self.parseAttributeName(c)

        case .attributeNameAfter:
            return self.parseAttributeNameAfter(c)

        case .attributeValueBefore:
            return self.parseAttributeValueBefore(c)

        case .attributeValueSingleQuote:
            return self.parseAttributeValue(c, q: "'")

        case .attributeValueDoubleQuote:
            return self.parseAttributeValue(c, q: "\"")

        case .attributeValueUnquoted:
            return self.parseAttributeValue(c, q: nil)

        case .attributeValueAfter:
            return self.parseAttributeValueAfter(c, generator: &generator)

        case .markupDeclarationOpen:
            // TODO: do not treat all decls as comments
            return self.parseMarkupDeclarationOpen(c, generator: &generator)

        case .bogusComment:
            return self.parseBogusComment(c)

        case .commentStart:
            return self.parseCommentStart(c)

        case .commentStartDash:
            return self.parseCommentStartDash(c)

        case .comment:
            return self.parseComment(c)

        case .commentEndDash:
            return self.parseCommentEndDash(c)

        case .commentEnd:
            return self.parseCommentEnd(c)

        case .cdata:
            return self.parseCDATA(c)

        case .cdataEndBracket:
            return self.parseCDATAEndBracket(c)

        case .cdataEndTag:
            return self.parseCDATAEndTag(c)

        default:
            // Argh
            break
        }

        return nil
    }

    // MARK: - Parser

    fileprivate func parseData(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "&":
            self.stateStack.append(self.state)
            self.state = .characterReference
        case "<":
            self.state = .tagOpen
            self.tempTagname = ""
            if self.tempBuffer.isEmpty == false {
                let token = HTML5Token.text(data: self.tempBuffer)
                self.tempBuffer = ""
                return token
            }
            else {
                self.tempBuffer = ""
            }
        default:
            self.tempBuffer.append(String(c))
        }
        return nil
    }

    fileprivate func parseCharRef(_ c: UnicodeScalar) -> UnicodeScalar? {
        switch c {
        case "\t", "\n", " ", "<", "&":
            self.state = self.stateStack.popLast()!
        case "#":
            // number mode
            self.charRefState = .number
        case "x":
            if self.charRefState == .number {
                self.charRefState = .hexNumber
            }
            else {
                self.charBuffer.append(String(c))
            }
        case ";":
            // parse temp buffer
            var result: UnicodeScalar
            switch self.charRefState {
            case .number:
                result = UnicodeScalar(strtol(self.charBuffer, nil, 10))!
            case .hexNumber:
                result = UnicodeScalar(strtol(self.charBuffer, nil, 16))!
            case .namedChar:
                result = self.parse(namedChar: self.charBuffer)
            }

            // reset
            self.state = self.stateStack.popLast()!
            self.charRefState = .namedChar
            self.charBuffer = ""
            return result
        default:
            self.charBuffer.append(String(c))
        }
        return nil
    }

    fileprivate func parseTagOpen(_ c: UnicodeScalar) -> HTML5Token? {
        self.tempAttributes = nil

        switch c {
        case "!":
            self.state = .markupDeclarationOpen
        case "/":
            self.state = .endTagOpen
        case "A"..."Z":
            self.tempTagname.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
            self.stateStack.append(self.state)
            self.state = .tagName
        case "a"..."z":
            self.tempTagname.append(String(c))
            self.stateStack.append(self.state)
            self.state = .tagName
        case "?":
            self.state = .bogusComment
        default:
            let token = HTML5Token.text(data: "<")
            self.tempBuffer = ""
            return token
        }
        return nil
    }

    fileprivate func parseEndTagOpen(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "A"..."Z":
            self.tempTagname.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
            self.stateStack.append(self.state)
            self.state = .tagName
        case "a"..."z":
            self.tempTagname.append(String(c))
            self.stateStack.append(self.state)
            self.state = .tagName
        case ">":
            self.state = .data
        default:
            self.state = .bogusComment
        }
        return nil
    }

    fileprivate func parseTagName(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .attributeNameBefore
        case "/":
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.tempTagname.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
            self.state = .tagName
        default:
            self.tempTagname.append(String(c))
        }
        return nil
    }

    fileprivate func parseSelfClosingStartTag(_ c: UnicodeScalar, generator: inout String.UnicodeScalarView.Iterator) -> HTML5Token? {
        switch c {
        case ">":
            return self.emitTag(true)
        default:
            self.state = .attributeNameBefore
            return self.consume(c, generator: &generator)
        }
    }

    fileprivate func parseAttributeNameBefore(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "/":
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.tempAttributeName = ""
            self.tempAttributeName.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
            self.state = .attributeName
        default:
            self.tempAttributeName = ""
            self.tempAttributeName.append(String(c))
            self.state = .attributeName
        }
        return nil
    }

    fileprivate func parseAttributeName(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .attributeNameAfter
        case "/":
            self.emitAttribute("")
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "=":
            self.state = .attributeValueBefore
        case "A"..."Z":
            self.tempAttributeName.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
        default:
            self.tempAttributeName.append(String(c))
        }
        return nil
    }

    fileprivate func parseAttributeNameAfter(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "/":
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.emitAttribute("")
            self.tempAttributeName.append(String(describing: UnicodeScalar(c.value + 32))) // lower case
            self.state = .attributeName
        default:
            self.emitAttribute("")
            self.tempAttributeName.append(String(c))
            self.state = .attributeName
        }
        return nil
    }

    fileprivate func parseAttributeValueBefore(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "\"":
            self.state = .attributeValueDoubleQuote
        case "&":
            self.stateStack.append(self.state)
            self.state = .characterReference
        case "'":
            self.state = .attributeValueSingleQuote

        case "/":
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        default:
            self.tempBuffer.append(String(c))
            self.state = .attributeValueUnquoted
        }
        return nil
    }

    fileprivate func parseAttributeValue(_ c: UnicodeScalar, q: UnicodeScalar?) -> HTML5Token? {
        if let q = q {
            switch c {
            case "&":
                self.stateStack.append(self.state)
                self.state = .characterReference
            case q:
                self.emitAttribute(self.tempBuffer)
                self.tempBuffer = ""
                self.state = .attributeValueAfter
            default:
                self.tempBuffer.append(String(c))
            }
        }
        else {
            switch c {
            case "\t", "\n", " ":
                self.emitAttribute(self.tempBuffer)
                self.tempBuffer = ""
                self.state = .attributeNameBefore
            case "&":
                self.stateStack.append(self.state)
                self.state = .characterReference
            case ">":
                self.emitTag(false)
            default:
                self.tempBuffer.append(String(c))
            }
        }
        return nil
    }

    fileprivate func parseAttributeValueAfter(_ c: UnicodeScalar, generator: inout String.UnicodeScalarView.Iterator) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .attributeNameBefore
        case "/":
            self.emitAttribute("")
            self.state = .selfClosingStartTag
        case ">":
            return self.emitTag(false)
        default:
            self.state = .attributeNameBefore
            return self.consume(c, generator: &generator)
        }
        return nil
    }

    fileprivate func parseMarkupDeclarationOpen(_ c: UnicodeScalar, generator: inout String.UnicodeScalarView.Iterator) -> HTML5Token? {
        switch c {
        case "-":
            if let cNext = generator.next() {
                if cNext == "-" {
                    self.state = .commentStart
                    break
                }
                else {
                    self.state = .bogusComment
                    self.consume(cNext, generator: &generator)
                }
            }
            self.state = .bogusComment
        case "[":
            var template = "CDATA[".unicodeScalars.makeIterator()
            var chars = [UnicodeScalar]()
            var parseError = false
            for _ in 0..<6 {
                if let c = generator.next() {
                    chars.append(c)
                    if template.next() != c {
                        parseError = true
                        break
                    }
                }
            }
            if parseError {
                self.state = .bogusComment
                for c in chars {
                    self.consume(c, generator: &generator)
                }
            }
            else {
                self.state = .cdata
            }
        default:
            self.state = .bogusComment
            return self.consume(c, generator: &generator)
        }
        return nil
    }

    fileprivate func parseBogusComment(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            self.state = .data
            let result = HTML5Token.comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.append(String(c))
        }
        return nil
    }

    fileprivate func parseCommentStart(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .commentStartDash
        case ">":
            self.state = .data
            let result = HTML5Token.comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.append(String(c))
            self.state = .comment
        }
        return nil
    }

    fileprivate func parseCommentStartDash(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .commentEnd
        case ">":
            self.state = .data
            let result = HTML5Token.comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.append("-")
            self.tempBuffer.append(String(c))
            self.state = .comment
        }
        return nil
    }

    fileprivate func parseComment(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .commentEndDash
        default:
            self.tempBuffer.append(String(c))
        }
        return nil
    }

    fileprivate func parseCommentEndDash(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .commentEnd
        default:
            self.tempBuffer.append("-")
            self.tempBuffer.append(String(c))
            self.state = .comment
        }
        return nil
    }

    fileprivate func parseCommentEnd(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            self.state = .data
            let result = HTML5Token.comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        case "!":
            self.state = .commentEndBang
        case "-":
            self.tempBuffer.append("-")
        default:
            self.tempBuffer.append("--")
            self.tempBuffer.append(String(c))
            self.state = .comment
        }
        return nil
    }

    fileprivate func parseCDATA(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "]":
            self.state = .cdataEndBracket
        default:
            self.tempBuffer.append(String(c))
        }
        return nil
    }

    fileprivate func parseCDATAEndBracket(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "]":
            self.state = .cdataEndTag
        default:
            self.tempBuffer.append("]")
            self.tempBuffer.append(String(c))
            self.state = .cdata
        }
        return nil
    }

    fileprivate func parseCDATAEndTag(_ c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            let result = HTML5Token.text(data: self.tempBuffer)
            self.tempBuffer = ""
            self.state = .data
            return result
        default:
            self.tempBuffer.append("]]")
            self.tempBuffer.append(String(c))
            self.state = .cdata
        }
        return nil
    }

    // MARK: - Helper

    fileprivate func emitAttribute(_ value: String) {
        if self.tempAttributeName.isEmpty == false {
            if self.tempAttributes == nil {
                self.tempAttributes = [String: String]()
            }
            self.tempAttributes![self.tempAttributeName] = value
            self.tempAttributeName = ""
        }
    }

    @discardableResult fileprivate func emitTag(_ selfClosing: Bool) -> HTML5Token? {
        self.emitAttribute("")

        self.state = .data
        let prevState = self.stateStack.popLast()!

        var result: HTML5Token?
        if prevState == .tagOpen {
            result = .startTag(name: self.tempTagname, selfClosing: selfClosing, attributes: self.tempAttributes)
        }
        if prevState == .endTagOpen {
            result = .endTag(name: self.tempTagname)
        }
        self.tempTagname = ""
        return result
    }
}
