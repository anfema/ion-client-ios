//
//  markdown.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

public enum NodeType {
    // Document level
    case document
    
    // Block level
    case heading(level: Int)
    case unorderedList(nestingDepth: Int)
    case unorderedListItem(nestingDepth: Int)
    case orderedList(nestingDepth: Int)
    case orderedListItem(index: Int, nestingDepth: Int)
    case codeBlock(language: String, nestingDepth: Int)
    case paragraph(nestingDepth: Int)
    case quote(nestingDepth: Int)

    // Inline
    case plainText
    case strongText
    case emphasizedText
    case deletedText
    case inlineCode
    case link(location: String)
    case image(location: String)
    
    public func debugDescription() -> String {
        switch(self) {
        case .document:
            return "Document-Node"
        case .heading(let level):
            return "Heading\(level)-Node"
        case .unorderedList(let nestingDepth):
            return "UnorderedList-Node (depth \(nestingDepth))"
        case .unorderedListItem:
            return "UnorderedListItem-Node"
        case .orderedList(let nestingDepth):
            return "OrderedList-Node (depth \(nestingDepth))"
        case .orderedListItem(let index):
            return "OrderedListItem(\(index))-Node"
        case .codeBlock(let language, let nestingDepth):
            return "CodeBlock-Node (lang: \(language), depth \(nestingDepth))"
        case .paragraph(let nestingDepth):
            return "Paragraph-Node (depth \(nestingDepth))"
        case .quote(let nestingDepth):
            return "Quote-Node (depth \(nestingDepth))"
        case .plainText:
            return "PlainText-Node"
        case .strongText:
            return "StrongText-Node"
        case .emphasizedText:
            return "EmphasizedText-Node"
        case .deletedText:
            return "DeletedText-Node"
        case .inlineCode:
            return "InlineCode-Node"
        case .link(let location):
            return "Link(\(location))-Node"
        case .image(let location):
            return "Image(\(location))-Node"
        }
    }
}

open class ContentNode: CustomDebugStringConvertible {
    let text:String
    var children:[ContentNode]
    let type:NodeType

    open var debugDescription: String {
        if self.children.count > 0 {
            var childrenDesc:String = self.type.debugDescription() + "\n"
            for child in self.children {
                let desc = child.debugDescription.replacingOccurrences(of: "\n    ", with: "\n        ")
                childrenDesc.append("    \(desc)\n")
            }
            return childrenDesc.trimmingCharacters(in: CharacterSet.newlines)
        } else {
            var txt = self.text.replacingOccurrences(of: "\n", with: "\\n")
            txt = txt.replacingOccurrences(of: "\t", with: "\\t")
            return "Text: '\(txt)'"
        }
    }
    
    init (text: String) {
        self.text = text
        self.type = .plainText
        self.children = []
    }
    
    init (children: [ContentNode], type: NodeType) {
        self.text = ""
        self.type = type
        self.children = children
    }
}

enum Block {
    case heading(level: Int, content: String)
    case unorderedList(content: String, nestingDepth: Int)
    case orderedList(content: String, nestingDepth: Int)
    case code(content: String, language: String, nestingDepth: Int)
    case paragraph(content: String, nestingDepth: Int)
    case quote(content:String, nestingDepth: Int)
}

open class MDParser {
    fileprivate let regexOptions: NSRegularExpression.Options = NSRegularExpression.Options.dotMatchesLineSeparators.union(NSRegularExpression.Options.caseInsensitive)
    fileprivate var markdown: String
    
    public init(markdown: String) {
        self.markdown = "\n\(markdown)\n"
    }

    open func render() -> ContentNode {
        var result:[ContentNode] = []
        
        for block in self.splitBlocks(self.markdown, nestingDepth: 0) {
            result.append(self.renderBlock(block))
        }
        
        return ContentNode(children: result, type: .document)
    }
    
    // MARK: - Block parsers
    
    func splitBlocks(_ string: String, nestingDepth: Int) -> [Block] {
        var blocks:[Block] = []

        let blockRegex = try! NSRegularExpression(pattern: "(\\n[^\\n]+)+", options: self.regexOptions)
        blockRegex.enumerateMatches(in: string, options: [], range: NSMakeRange(0, string.unicodeScalars.count)) { (result, _, _) in
            if let result = result {
                blocks.append(self.identifyBlock(string.substringWithRange(result.range)!, nestingDepth: nestingDepth))
            }
        }
        return blocks
    }

    func splitBlocksByIndent(_ string: String, nestingDepth: Int) -> [Block] {
        var blocks:[Block] = []
        let paddedString = "\n" + string + "\n"
        let fullString = NSMakeRange(0, paddedString.characters.count)
        
        let blockRegex = try! NSRegularExpression(pattern: "(\\n[ ]{0,3}([^ ][^\\n]+))+|((\\n([ ]{4}|\\t)[^\\n]+)+)", options: self.regexOptions)
        blockRegex.enumerateMatches(in: paddedString, options: [], range: fullString) { (result, _, _) in
            if let result = result {
                let s = ("\n" + string).substringWithRange(result.range)!.replacingOccurrences(of: "\n    ", with: "\n")
                blocks.append(self.identifyBlock(s, nestingDepth: nestingDepth))
            }
        }
        return blocks
    }

    func identifyBlock(_ string: String, nestingDepth: Int) -> Block {
        let stripped = string.trimmingCharacters(in: CharacterSet.newlines)
        let fullString = NSMakeRange(0, stripped.characters.count)
        
        // Identify Headings
        let headingRegexes:[NSRegularExpression] = [
            try! NSRegularExpression(pattern: "(^#####[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\^]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^####[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\-]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^###[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\+]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^##[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[=]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^#[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[#]+\\n)", options: self.regexOptions)
        ]

        var level = headingRegexes.count
        var resultBlock: Block? = nil
        let hString = stripped + "\n"
        let hStringRange = NSMakeRange(0, hString.characters.count)
        for regex in headingRegexes {
            regex.enumerateMatches(in: hString, options: [], range: hStringRange) { (result, _, _) in
                if let result = result {
                    if result.rangeAt(2).location != NSNotFound {
                        resultBlock = Block.heading(level: level, content: hString.substringWithRange(result.rangeAt(2))!)
                    }
                    if result.rangeAt(4).location != NSNotFound {
                        resultBlock = Block.heading(level: level, content: hString.substringWithRange(result.rangeAt(4))!)
                    }
                }
            }
            if resultBlock != nil {
                return resultBlock!
            }
            level -= 1
        }
        
        // Identify unordered lists
        let unorderedListRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[\\-+*][ \\t]+)", options: self.regexOptions)
        if unorderedListRegex.numberOfMatches(in: stripped, options: [], range: fullString) > 0 {
            return Block.unorderedList(content: stripped, nestingDepth: nestingDepth)
        }
        
        // Identify ordered lists
        let orderedListRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[0-9a-z][.\\)][ \\t]+)", options: self.regexOptions)
        if orderedListRegex.numberOfMatches(in: stripped, options: [], range: fullString) > 0 {
            return Block.orderedList(content: stripped, nestingDepth: nestingDepth)
        }

        // Identify code
        let codeRegexSpaces = try! NSRegularExpression(pattern: "(^[ ]{4}[^\\n]*)", options: self.regexOptions)
        let codeRegexTab = try! NSRegularExpression(pattern: "(^\\t[^\\n]*)", options: self.regexOptions)
        let codeRegexFences = try! NSRegularExpression(pattern: "(^[`~]{3,}([^\\n]*)\\n(.*)[`~]{3,})", options: self.regexOptions)
        var language:String = "text"
        if codeRegexSpaces.numberOfMatches(in: stripped, options: [], range: fullString) > 0 {
            let modified = ("\n" + stripped).replacingOccurrences(of: "\n    ", with: "\n").trimmingCharacters(in: CharacterSet.newlines)
            return Block.code(content: modified, language: language, nestingDepth: nestingDepth)
        }
        if codeRegexTab.numberOfMatches(in: stripped, options: [], range: fullString) > 0 {
            let modified = ("\n" + stripped).replacingOccurrences(of: "\n\t", with: "\n").trimmingCharacters(in: CharacterSet.newlines)
            return Block.code(content: modified, language: language, nestingDepth: nestingDepth)
        }
        codeRegexFences.enumerateMatches(in: stripped, options: [], range: fullString) { (result, _, _) in
            if let result = result {
                if ((result.rangeAt(2).location != NSNotFound) && (result.rangeAt(2).length > 0)) {
                    language = stripped.substringWithRange(result.rangeAt(2))!
                }
                if result.rangeAt(3).location != NSNotFound {
                    resultBlock = Block.code(content: stripped.substringWithRange(result.rangeAt(3))!, language: language, nestingDepth: nestingDepth + 1)
                }
            }
        }
        if resultBlock != nil {
            return resultBlock!
        }

        // Identify quote
        let quoteRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[>]+[ \\t]*)|(\\n[ ]{0,3}[>]+[ \\t]*)", options: self.regexOptions)
        if quoteRegex.numberOfMatches(in: stripped, options: [], range: fullString) > 0 {
            let modified = quoteRegex.stringByReplacingMatches(in: stripped, options: [], range: fullString, withTemplate: "\n").trimmingCharacters(in: CharacterSet.newlines)
            return Block.quote(content: modified, nestingDepth: nestingDepth)
        }
        
        // Everything else is just a paragraph
        return Block.paragraph(content: stripped, nestingDepth: nestingDepth)
    }
    
    // MARK: - Block content recursive parsers
    
    func renderBlock(_ block: Block) -> ContentNode {
        switch (block) {
        case .heading(let level, let content):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .heading(level: level))
        case .unorderedList(let content, let nestingDepth):
            let items = self.splitUnorderedListItems(content, nestingDepth: nestingDepth)
            return ContentNode(children: items, type: .unorderedList(nestingDepth: nestingDepth))
        case .orderedList(let content, let nestingDepth):
            let items = self.splitOrderedListItems(content, nestingDepth: nestingDepth)
            return ContentNode(children: items, type: .orderedList(nestingDepth: nestingDepth))
        case .code(let content, let language, let nestingDepth):
            return ContentNode(children: [ContentNode.init(text: content)], type: .codeBlock(language: language, nestingDepth: nestingDepth))
        case .paragraph(let content, let nestingDepth):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .paragraph(nestingDepth: nestingDepth))
        case .quote(let content, let nestingDepth):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .quote(nestingDepth: nestingDepth))
        }
    }
    
    func parseContent(_ string: String) -> [ContentNode] {
        let trimRegex = try! NSRegularExpression(pattern: "\\n[ ]{0,3}", options: self.regexOptions)
        let fullString = NSMakeRange(0, string.characters.count)
        let trimmedString = trimRegex.stringByReplacingMatches(in: string, options: [], range: fullString, withTemplate: "\n")
        
        var tokens = self.parseInlineCode(trimmedString)
        
        if tokens == nil {
            tokens = self.parseStrongText(trimmedString)
        }
        if tokens == nil {
            tokens = self.parseEmphasizedText(trimmedString)
        }
        if tokens == nil {
            tokens = self.parseDeletedText(trimmedString)
        }
        if tokens == nil {
            tokens = self.parseImages(trimmedString)
        }
        if tokens == nil {
            tokens = self.parseLinks(trimmedString)
        }
        
        if let t = tokens, t.count > 1 {
            var newTokens:[ContentNode] = []
            for token in t {
                if case .plainText = token.type {
                    let subTokens = self.parseContent(token.text)
                    if subTokens.count > 0 {
                        newTokens.append(contentsOf: subTokens)
                        continue
                    }
                }
                newTokens.append(token)
            }
            return newTokens
        } else {
            if tokens == nil {
                return [ContentNode(text: trimmedString)]
            } else {
                return tokens!
            }
        }
    }
    
    func splitUnorderedListItems(_ string: String, nestingDepth: Int) -> [ContentNode] {
        var tokens = [ContentNode]()
        let paddedString = string + "\n"
        let fullString = NSMakeRange(0, paddedString.characters.count)
        
        let splitListRegex = try! NSRegularExpression(pattern: "([ ]{0,3}[\\-*+][^\\-*+]([^\\n]*\\n([ \\t]+[^\\n]+\\n)+))|([ ]{0,3}[\\-*+][^\\-*+]([^\\n]*)\\n)", options: self.regexOptions)
        let matches = splitListRegex.matches(in: paddedString, options: [], range: fullString)
        for index in 0..<matches.count {
            let match = matches[index]
            
            if let multilineItem = paddedString.substringWithRange(match.rangeAt(2)), multilineItem.characters.count > 0 {
                var result:[ContentNode] = []
                
                for block in self.splitBlocksByIndent(multilineItem, nestingDepth: nestingDepth + 1) {
                    result.append(self.renderBlock(block))
                }
                
                tokens.append(ContentNode.init(children: result, type: .unorderedListItem(nestingDepth: nestingDepth)))
            }
            if let singleLineItem = paddedString.substringWithRange(match.rangeAt(5)), singleLineItem.characters.count > 0 {
                let node = self.parseContent(singleLineItem)
                tokens.append(ContentNode.init(children: node, type: .unorderedListItem(nestingDepth: nestingDepth)))
            }
        }
        return tokens
    }

    func splitOrderedListItems(_ string: String, nestingDepth: Int) -> [ContentNode] {
        var tokens = [ContentNode]()
        let paddedString = string + "\n"
        let fullString = NSMakeRange(0, paddedString.characters.count)
        
        let splitListRegex = try! NSRegularExpression(pattern: "([ ]{0,3}[0-9a-z]+[.\\)][ \\t]*([^\\n]*\\n([ \\t]+[^\\n]+\\n)+))|([ ]{0,3}[0-9a-z]+[.\\)][ \\t]*([^\\n]*)\\n)", options: self.regexOptions)
        let matches = splitListRegex.matches(in: paddedString, options: [], range: fullString)
        for index in 0..<matches.count {
            let match = matches[index]
            
            if let multilineItem = paddedString.substringWithRange(match.rangeAt(2)), multilineItem.characters.count > 0 {
                var result:[ContentNode] = []
                
                for block in self.splitBlocksByIndent(multilineItem, nestingDepth: nestingDepth + 1) {
                    result.append(self.renderBlock(block))
                }
                
                tokens.append(ContentNode.init(children: result, type: .orderedListItem(index: index + 1, nestingDepth: nestingDepth)))
            }
            if let singleLineItem = paddedString.substringWithRange(match.rangeAt(5)), singleLineItem.characters.count > 0 {
                let node = self.parseContent(singleLineItem)
                tokens.append(ContentNode.init(children: node, type: .orderedListItem(index: index + 1, nestingDepth: nestingDepth)))
            }
        }
        return tokens
    }
    
    // MARK: Inline content parsers

    func parseInlineCode(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        
        // case InlineCode
        let inlineCodeRegex = try! NSRegularExpression(pattern: "`([^`\\n]+)`", options: self.regexOptions)
        inlineCodeRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .inlineCode))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }
    
    func parseStrongText(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case StrongText
        let strongTextRegex = try! NSRegularExpression(pattern: "[\\*_]{2}([^\\*_\\n]+)[\\*_]{2}", options: self.regexOptions)
        strongTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .strongText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }
    
    func parseEmphasizedText(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case EmphasizedText
        let emTextRegex = try! NSRegularExpression(pattern: "[\\*_]{1}([^\\*_\\n]+)[\\*_]{1}", options: self.regexOptions)
        emTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .emphasizedText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseDeletedText(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case DeletedText
        let delTextRegex = try! NSRegularExpression(pattern: "[~]{2}([^~\\n]+)[~]{2}", options: self.regexOptions)
        delTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .deletedText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseLinks(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        let fullString = NSMakeRange(0, string.characters.count)

        let linkRegex = try! NSRegularExpression(pattern: "\\[([^\\]]*)\\]\\(((#|[0-9a-z]+://)[^)\\n]*)\\)", options: self.regexOptions)
        let matches = linkRegex.matches(in: string, options: [], range: fullString)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substring(with: string.range(lastSplitPoint, end:match.range.location)!)
                if t.characters.count > 0 {
                    tokens.append(ContentNode.init(text: t))
                }
                // the token match
                let textNode = ContentNode.init(text: string.substringWithRange(match.rangeAt(1))!)
                tokens.append(ContentNode.init(children: [textNode], type: .link(location: string.substringWithRange(match.rangeAt(2))!)))
            }
            
            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substring(with: string.range(lastSplitPoint, end:string.characters.count)!)
            if t.characters.count > 0 {
                tokens.append(ContentNode.init(text: t))
            }
        }
        
        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseImages(_ string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        let fullString = NSMakeRange(0, string.characters.count)
        
        let linkRegex = try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(([a-z0-9]+://[^)\\n]*)\\)", options: self.regexOptions)
        let matches = linkRegex.matches(in: string, options: [], range: fullString)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substring(with: string.range(lastSplitPoint, end:match.range.location)!)
                if t.characters.count > 0 {
                    tokens.append(ContentNode.init(text: t))
                }
                // the token match
                let textNode = ContentNode.init(text: string.substringWithRange(match.rangeAt(1))!)
                tokens.append(ContentNode.init(children: [textNode], type: .image(location: string.substringWithRange(match.rangeAt(2))!)))
            }
            
            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substring(with: string.range(lastSplitPoint, end:string.characters.count)!)
            if t.characters.count > 0 {
                tokens.append(ContentNode.init(text: t))
            }
        }
        
        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

}

