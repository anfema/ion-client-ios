//
//  tokenizer.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

public class HTML5Tokenizer {
    /// The HTML to tokenize
    private let html:String
    
    /// Temporary buffer to accumulate Strings in
    private var tempBuffer: String
    private var charBuffer: String
    private var tempTagname: String
    private var tempAttributeName: String
    private var tempAttributes:[String:String]?
    
    /// current state machine state
    private var state:TokenizerState = .Data
    private var stateStack = [TokenizerState]()
    
    private var charRefState:CharRefState = .NamedChar
    
    public init(htmlString: String) {
        self.html = htmlString
        self.tempBuffer = ""
        self.charBuffer = ""
        self.tempTagname = ""
        self.tempAttributeName = ""
    }
    
    public func tokenize() -> [HTML5Token] {
        var result = [HTML5Token]()
        var generator = self.html.unicodeScalars.generate()
        self.state = .Data

        while let c = generator.next() {
            if let token = self.consume(c, generator: &generator) {
                result.append(token)
            }
        }
        
        if self.state == .Data && self.tempBuffer.characters.count > 0 {
            result.append(.Text(data: self.tempBuffer))
            self.tempBuffer = ""
        }
        
        return result
    }
    
    private func consume(c: UnicodeScalar, inout generator: String.UnicodeScalarView.Generator) -> HTML5Token? {
        
        switch self.state {
            
        case .Data:
            return self.parseData(c)
            
        case .CharacterReference:
            if let char = self.parseCharRef(c) {
                self.tempBuffer.append(char)
            }
            
        case .TagOpen:
            return self.parseTagOpen(c)
            
        case .EndTagOpen:
            return self.parseEndTagOpen(c)
            
        case .TagName:
            return self.parseTagName(c)
            
        case .SelfClosingStartTag:
            return self.parseSelfClosingStartTag(c, generator: &generator)
            
        case .AttributeNameBefore:
            return self.parseAttributeNameBefore(c)
            
        case .AttributeName:
            return self.parseAttributeName(c)
            
        case .AttributeNameAfter:
            return self.parseAttributeNameAfter(c)
            
        case .AttributeValueBefore:
            return self.parseAttributeValueBefore(c)
            
        case .AttributeValueSingleQuote:
            return self.parseAttributeValue(c, q: "'")
            
        case .AttributeValueDoubleQuote:
            return self.parseAttributeValue(c, q: "\"")
            
        case .AttributeValueUnquoted:
            return self.parseAttributeValue(c, q: nil)
            
        case .AttributeValueAfter:
            return self.parseAttributeValueAfter(c, generator: &generator)
        
        case .MarkupDeclarationOpen:
            // TODO: do not treat all decls as comments
            return self.parseMarkupDeclarationOpen(c, generator: &generator)
        
        case .BogusComment:
            return self.parseBogusComment(c)

        case .CommentStart:
            return self.parseCommentStart(c)

        case .CommentStartDash:
            return self.parseCommentStartDash(c)

        case .Comment:
            return self.parseComment(c)
        
        case .CommentEndDash:
            return self.parseCommentEndDash(c)
        
        case .CommentEnd:
            return self.parseCommentEnd(c)
        
        case .CDATA:
            return self.parseCDATA(c)
            
        case .CDATAEndBracket:
            return self.parseCDATAEndBracket(c)
            
        case .CDATAEndTag:
            return self.parseCDATAEndTag(c)
            
        default:
            // Argh
            break
        }
        
        return nil
    }
    
    // MARK: - Parser
    
    private func parseData(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "&":
            self.stateStack.append(self.state)
            self.state = .CharacterReference
        case "<":
            self.state = .TagOpen
            self.tempTagname = ""
            if self.tempBuffer.characters.count > 0 {
                let token = HTML5Token.Text(data: self.tempBuffer)
                self.tempBuffer = ""
                return token
            } else {
                self.tempBuffer = ""
            }
        default:
            self.tempBuffer.append(c)
        }
        return nil
    }
    
    private func parseCharRef(c: UnicodeScalar) -> UnicodeScalar? {
        switch c {
        case "\t", "\n", " ", "<", "&":
            self.state = self.stateStack.popLast()!
        case "#":
            // number mode
            self.charRefState = .Number
        case "x":
            if self.charRefState == .Number {
                self.charRefState = .HexNumber
            } else {
                self.charBuffer.append(c)
            }
        case ";":
            // parse temp buffer
            var result:UnicodeScalar
            switch self.charRefState {
            case .Number:
                result = UnicodeScalar(strtol(self.charBuffer, nil, 10))
            case .HexNumber:
                result = UnicodeScalar(strtol(self.charBuffer, nil, 16))
            case .NamedChar:
                result = self.parseNamedChar(self.charBuffer)
            }
            
            // reset
            self.state = self.stateStack.popLast()!
            self.charRefState = .NamedChar
            self.charBuffer = ""
            return result
        default:
            self.charBuffer.append(c)
        }
        return nil
    }
    
    private func parseTagOpen(c: UnicodeScalar) -> HTML5Token? {
        self.tempAttributes = nil

        switch c {
        case "!":
            self.state = .MarkupDeclarationOpen
        case "/":
            self.state = .EndTagOpen
        case "A"..."Z":
            self.tempTagname.append(UnicodeScalar(c.value + 32)) // lower case
            self.stateStack.append(self.state)
            self.state = .TagName
        case "a"..."z":
            self.tempTagname.append(c)
            self.stateStack.append(self.state)
            self.state = .TagName
        case "?":
            self.state = .BogusComment
        default:
            let token = HTML5Token.Text(data: "<")
            self.tempBuffer = ""
            return token
        }
        return nil
    }
    
    private func parseEndTagOpen(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "A"..."Z":
            self.tempTagname.append(UnicodeScalar(c.value + 32)) // lower case
            self.stateStack.append(self.state)
            self.state = .TagName
        case "a"..."z":
            self.tempTagname.append(c)
            self.stateStack.append(self.state)
            self.state = .TagName
        case ">":
            self.state = .Data
        default:
            self.state = .BogusComment
        }
        return nil
    }
    
    private func parseTagName(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .AttributeNameBefore
        case "/":
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.tempTagname.append(UnicodeScalar(c.value + 32)) // lower case
            self.state = .TagName
        default:
            self.tempTagname.append(c)
        }
        return nil
    }

    private func parseSelfClosingStartTag(c: UnicodeScalar, inout generator: String.UnicodeScalarView.Generator) -> HTML5Token? {
        switch c {
        case ">":
            return self.emitTag(true)
        default:
            self.state = .AttributeNameBefore
            return self.consume(c, generator: &generator)
        }
    }
    
    private func parseAttributeNameBefore(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "/":
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.tempAttributeName = ""
            self.tempAttributeName.append(UnicodeScalar(c.value + 32)) // lower case
            self.state = .AttributeName
        default:
            self.tempAttributeName = ""
            self.tempAttributeName.append(c)
            self.state = .AttributeName
        }
        return nil
    }

    private func parseAttributeName(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .AttributeNameAfter
        case "/":
            self.emitAttribute("")
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "=":
            self.state = .AttributeValueBefore
        case "A"..."Z":
            self.tempAttributeName.append(UnicodeScalar(c.value + 32)) // lower case
        default:
            self.tempAttributeName.append(c)
        }
        return nil
    }

    private func parseAttributeNameAfter(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "/":
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        case "A"..."Z":
            self.emitAttribute("")
            self.tempAttributeName.append(UnicodeScalar(c.value + 32)) // lower case
            self.state = .AttributeName
        default:
            self.emitAttribute("")
            self.tempAttributeName.append(c)
            self.state = .AttributeName
        }
        return nil
    }

    private func parseAttributeValueBefore(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            break
        case "\"":
            self.state = .AttributeValueDoubleQuote
        case "&":
            self.stateStack.append(self.state)
            self.state = .CharacterReference
        case "'":
            self.state = .AttributeValueSingleQuote
            
        case "/":
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        default:
            self.tempBuffer.append(c)
            self.state = .AttributeValueUnquoted
        }
        return nil
    }

    private func parseAttributeValue(c: UnicodeScalar, q: UnicodeScalar?) -> HTML5Token? {
        if let q = q {
            switch c {
            case "&":
                self.stateStack.append(self.state)
                self.state = .CharacterReference
            case q:
                self.emitAttribute(self.tempBuffer)
                self.tempBuffer = ""
                self.state = .AttributeValueAfter
            default:
                self.tempBuffer.append(c)
            }
        } else {
            switch c {
            case "\t", "\n", " ":
                self.emitAttribute(self.tempBuffer)
                self.tempBuffer = ""
                self.state = .AttributeNameBefore
            case "&":
                self.stateStack.append(self.state)
                self.state = .CharacterReference
            case ">":
                self.emitTag(false)
            default:
                self.tempBuffer.append(c)
            }
        }
        return nil
    }
    
    private func parseAttributeValueAfter(c: UnicodeScalar, inout generator: String.UnicodeScalarView.Generator) -> HTML5Token? {
        switch c {
        case "\t", "\n", " ":
            self.state = .AttributeNameBefore
        case "/":
            self.emitAttribute("")
            self.state = .SelfClosingStartTag
        case ">":
            return self.emitTag(false)
        default:
            self.state = .AttributeNameBefore
            return self.consume(c, generator: &generator)
        }
        return nil
    }
    
    private func parseMarkupDeclarationOpen(c: UnicodeScalar, inout generator: String.UnicodeScalarView.Generator) -> HTML5Token? {
        switch c {
        case "-":
            if let cNext = generator.next() {
                if cNext == "-" {
                    self.state = .CommentStart
                    break
                } else {
                    self.state = .BogusComment
                    self.consume(cNext, generator: &generator)
                }
            }
            self.state = .BogusComment
        case "[":
            var template = "CDATA[".unicodeScalars.generate()
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
            if (parseError) {
                self.state = .BogusComment
                for c in chars {
                    self.consume(c, generator: &generator)
                }
            } else {
                self.state = .CDATA
            }
        default:
            self.state = .BogusComment
            return self.consume(c, generator: &generator)
        }
        return nil
    }
    
    private func parseBogusComment(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            self.state = .Data
            let result = HTML5Token.Comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.append(c)
        }
        return nil
    }

    private func parseCommentStart(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .CommentStartDash
        case ">":
            self.state = .Data
            let result = HTML5Token.Comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.append(c)
            self.state = .Comment
        }
        return nil
    }

    private func parseCommentStartDash(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .CommentEnd
        case ">":
            self.state = .Data
            let result = HTML5Token.Comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        default:
            self.tempBuffer.appendContentsOf("-")
            self.tempBuffer.append(c)
            self.state = .Comment
        }
        return nil
    }

    private func parseComment(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .CommentEndDash
        default:
            self.tempBuffer.append(c)
        }
        return nil
    }

    private func parseCommentEndDash(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "-":
            self.state = .CommentEnd
        default:
            self.tempBuffer.appendContentsOf("-")
            self.tempBuffer.append(c)
            self.state = .Comment
        }
        return nil
    }
    
    private func parseCommentEnd(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            self.state = .Data
            let result = HTML5Token.Comment(data: self.tempBuffer)
            self.tempBuffer = ""
            return result
        case "!":
            self.state = .CommentEndBang
        case "-":
            self.tempBuffer.appendContentsOf("-")
        default:
            self.tempBuffer.appendContentsOf("--")
            self.tempBuffer.append(c)
            self.state = .Comment
        }
        return nil
    }

    private func parseCDATA(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "]":
            self.state = .CDATAEndBracket
        default:
            self.tempBuffer.append(c)
        }
        return nil
    }

    private func parseCDATAEndBracket(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "]":
            self.state = .CDATAEndTag
        default:
            self.tempBuffer.appendContentsOf("]")
            self.tempBuffer.append(c)
            self.state = .CDATA
        }
        return nil
    }

    private func parseCDATAEndTag(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            let result = HTML5Token.Text(data: self.tempBuffer)
            self.tempBuffer = ""
            self.state = .Data
            return result
        default:
            self.tempBuffer.appendContentsOf("]]")
            self.tempBuffer.append(c)
            self.state = .CDATA
        }
        return nil
    }

    // MARK: - Helper
    
    private func emitAttribute(value: String) {
        if self.tempAttributeName.characters.count > 0 {
            if self.tempAttributes == nil {
                self.tempAttributes = [String:String]()
            }
            self.tempAttributes![self.tempAttributeName] = value
            self.tempAttributeName = ""
        }
    }
    
    private func emitTag(selfClosing: Bool) -> HTML5Token? {
        self.emitAttribute("")

        self.state = .Data
        let prevState = self.stateStack.popLast()!
        
        var result:HTML5Token? = nil
        if prevState == .TagOpen {
            result = .StartTag(name: self.tempTagname, selfClosing: selfClosing, attributes: self.tempAttributes)
        }
        if prevState == .EndTagOpen {
            result = .EndTag(name: self.tempTagname)
        }
        self.tempTagname = ""
        return result
    }
}