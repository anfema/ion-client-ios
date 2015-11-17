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
    }
    
    public func tokenize() -> [HTML5Token] {
        var result = [HTML5Token]()
        var generator = self.html.unicodeScalars.generate()
        self.state = .Data

        while let c = generator.next() {
            var token:HTML5Token? = nil
            
            switch self.state {

            case .Data:
                token = self.parseData(c)
            
            case .CharacterReference:
                if let char = self.parseCharRef(c) {
                    self.tempBuffer.append(char)
                }
            
            case .TagOpen:
                token = self.parseTagOpen(c)
                
            case .EndTagOpen:
                token = self.parseEndTagOpen(c)
                
            case .TagName:
                token = self.parseTagName(c)

            case .SelfClosingStartTag:
                token = self.parseSelfClosingStartTag(c)

            case .AttributeNameBefore:
                break
            
            case .AttributeName:
                break
            
            case .AttributeNameAfter:
                break
            
            case .AttributeValueBefore:
                break
            
            case .AttributeValueSingleQuote:
                break
                
            case .AttributeValueDoubleQuote:
                break
            
            case .AttributeValueUnquoted:
                break
            
            case .AttributeValueAfter:
                break
            
                
            default:
                // Argh
                break
            }
            
            if let token = token {
                result.append(token)
            }
        }
        
        if self.state == .Data && self.tempBuffer.characters.count > 0 {
            result.append(.Text(data: self.tempBuffer))
            self.tempBuffer = ""
        }
        
        return result
    }
    
    
    
    
    private func parseData(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case "&":
            self.stateStack.append(.Data)
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
            self.stateStack.append(.TagOpen)
            self.state = .TagName
        case "a"..."z":
            self.tempTagname.append(c)
            self.stateStack.append(.TagOpen)
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
            self.stateStack.append(.EndTagOpen)
            self.state = .TagName
        case "a"..."z":
            self.tempTagname.append(c)
            self.stateStack.append(.EndTagOpen)
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
            self.state = .Data
            let prevState = self.stateStack.popLast()!
            
            var result:HTML5Token? = nil
            if prevState == .TagOpen {
                result = .StartTag(name: self.tempTagname, selfClosing: false, attributes: self.tempAttributes)
            }
            if prevState == .EndTagOpen {
                result = .EndTag(name: self.tempTagname)
            }
            self.tempTagname = ""
            return result
        case "A"..."Z":
            self.tempTagname.append(UnicodeScalar(c.value + 32)) // lower case
            self.stateStack.append(.EndTagOpen)
            self.state = .TagName
        default:
            self.tempTagname.append(c)
        }
        return nil
    }

    private func parseSelfClosingStartTag(c: UnicodeScalar) -> HTML5Token? {
        switch c {
        case ">":
            self.state = .Data
            let prevState = self.stateStack.popLast()!
            
            var result:HTML5Token? = nil
            if prevState == .TagOpen {
                result = .StartTag(name: self.tempTagname, selfClosing: true, attributes: self.tempAttributes)
            }
            if prevState == .EndTagOpen {
                result = .EndTag(name: self.tempTagname)
            }
            self.tempTagname = ""
            return result
        default:
            self.state = .AttributeNameBefore
            self.tempBuffer.append(c)
        }
        return nil
    }
}