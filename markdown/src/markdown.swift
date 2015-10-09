//
//  markdown.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

public enum NodeType {
    // Document level
    case Document
    
    // Block level
    case Heading(level: Int)
    case UnorderedList
    case UnorderedListItem
    case OrderedList
    case OrderedListItem(index: Int)
    case CodeBlock(language: String)
    case Paragraph
    case Quote

    // Inline
    case PlainText
    case StrongText
    case EmphasizedText
    case DeletedText
    case InlineCode
    case Link(location: String)
    case Image(location: String)
    
    public func debugDescription() -> String {
        switch(self) {
        case .Document:
            return "Document-Node"
        case .Heading(let level):
            return "Heading\(level)-Node"
        case .UnorderedList:
            return "UnorderedList-Node"
        case .UnorderedListItem:
            return "UnorderedListItem-Node"
        case .OrderedList:
            return "OrderedList-Node"
        case .OrderedListItem(let index):
            return "OrderedListItem(\(index))-Node"
        case .CodeBlock(let language):
            return "CodeBlock(\(language))-Node"
        case .Paragraph:
            return "Paragraph-Node"
        case .Quote:
            return "Quote-Node"
        case .PlainText:
            return "PlainText-Node"
        case .StrongText:
            return "StrongText-Node"
        case .EmphasizedText:
            return "EmphasizedText-Node"
        case .DeletedText:
            return "DeletedText-Node"
        case .InlineCode:
            return "InlineCode-Node"
        case .Link(let location):
            return "Link(\(location))-Node"
        case .Image(let location):
            return "Image(\(location))-Node"
        }
    }
}

public class ContentNode: CustomDebugStringConvertible {
    let text:String
    var children:[ContentNode]
    let type:NodeType

    public var debugDescription: String {
        if self.children.count > 0 {
            var childrenDesc:String = self.type.debugDescription() + "\n"
            for child in self.children {
                let desc = child.debugDescription.stringByReplacingOccurrencesOfString("\n    ", withString: "\n        ")
                childrenDesc.appendContentsOf("    \(desc)\n")
            }
            return childrenDesc.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        } else {
            var txt = self.text.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
            txt = txt.stringByReplacingOccurrencesOfString("\t", withString: "\\t")
            return "Text: '\(txt)'"
        }
    }
    
    init (text: String) {
        self.text = text
        self.type = .PlainText
        self.children = []
    }
    
    init (children: [ContentNode], type: NodeType) {
        self.text = ""
        self.type = type
        self.children = children
    }
}

enum Block {
    case Heading(level: Int, content: String)
    case UnorderedList(content: String)
    case OrderedList(content: String)
    case Code(content: String, language: String)
    case Paragraph(content: String)
    case Quote(content:String)
}

public class MDParser {
    private let regexOptions: NSRegularExpressionOptions = NSRegularExpressionOptions.DotMatchesLineSeparators.union(NSRegularExpressionOptions.CaseInsensitive)
    private var markdown: String
    
    public init(markdown: String) {
        self.markdown = "\n\(markdown)\n"
    }

    public func render() -> ContentNode {
        var result:[ContentNode] = []
        
        for block in self.splitBlocks(self.markdown) {
            result.append(self.renderBlock(block))
        }
        
        return ContentNode(children: result, type: .Document)
    }
    
    // MARK: - Block parsers
    
    func splitBlocks(string: String) -> [Block] {
        var blocks:[Block] = []

        let blockRegex = try! NSRegularExpression(pattern: "(\\n[^\\n]+)+", options: self.regexOptions)
        blockRegex.enumerateMatchesInString(string, options: [], range: NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))) { (result, _, _) in
            if let result = result {
                blocks.append(self.identifyBlock(string.substringWithRange(result.range)!))
            }
        }
        return blocks
    }

    func splitBlocksByIndent(string: String) -> [Block] {
        var blocks:[Block] = []
        let paddedString = "\n" + string + "\n"
        let fullString = NSMakeRange(0, paddedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let blockRegex = try! NSRegularExpression(pattern: "(\\n[ ]{0,3}([^ ][^\\n]+))+|((\\n([ ]{4}|\\t)[^\\n]+)+)", options: self.regexOptions)
        blockRegex.enumerateMatchesInString(paddedString, options: [], range: fullString) { (result, _, _) in
            if let result = result {
                let s = ("\n" + string).substringWithRange(result.range)!.stringByReplacingOccurrencesOfString("\n    ", withString: "\n")
                blocks.append(self.identifyBlock(s))
            }
        }
        return blocks
    }

    func identifyBlock(string: String) -> Block {
        let stripped = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
        let fullString = NSMakeRange(0, stripped.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        // Identify Headings
        let headingRegexes:[NSRegularExpression] = [
            try! NSRegularExpression(pattern: "(^#[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[#]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^##[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[=]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^###[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\+]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^####[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\-]+\\n)", options: self.regexOptions),
            try! NSRegularExpression(pattern: "(^#####[ \\t]*([^\\n]*))|(^([^\\n]*)\\n[\\^]+\\n)", options: self.regexOptions)
        ]

        var level = 1
        var resultBlock: Block? = nil
        let hString = stripped + "\n"
        let hStringRange = NSMakeRange(0, hString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        for regex in headingRegexes {
            regex.enumerateMatchesInString(hString, options: [], range: hStringRange) { (result, _, _) in
                if let result = result {
                    if result.rangeAtIndex(2).location != NSNotFound {
                        resultBlock = Block.Heading(level: level, content: hString.substringWithRange(result.rangeAtIndex(2))!)
                    }
                    if result.rangeAtIndex(4).location != NSNotFound {
                        resultBlock = Block.Heading(level: level, content: hString.substringWithRange(result.rangeAtIndex(4))!)
                    }
                }
            }
            if resultBlock != nil {
                return resultBlock!
            }
            level++
        }
        
        // Identify unordered lists
        let unorderedListRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[\\-+*][ \\t]+)", options: self.regexOptions)
        if unorderedListRegex.numberOfMatchesInString(stripped, options: [], range: fullString) > 0 {
            return Block.UnorderedList(content: stripped)
        }
        
        // Identify ordered lists
        let orderedListRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[0-9a-z][.\\)][ \\t]+)", options: self.regexOptions)
        if orderedListRegex.numberOfMatchesInString(stripped, options: [], range: fullString) > 0 {
            return Block.OrderedList(content: stripped)
        }

        // Identify code
        let codeRegexSpaces = try! NSRegularExpression(pattern: "(^[ ]{4}[^\\n]*)", options: self.regexOptions)
        let codeRegexTab = try! NSRegularExpression(pattern: "(^\\t[^\\n]*)", options: self.regexOptions)
        let codeRegexFences = try! NSRegularExpression(pattern: "(^[`~]{3,}([^\\n]*)\\n(.*)[`~]{3,})", options: self.regexOptions)
        var language:String = "text"
        if codeRegexSpaces.numberOfMatchesInString(stripped, options: [], range: fullString) > 0 {
            let modified = ("\n" + stripped).stringByReplacingOccurrencesOfString("\n    ", withString: "\n").stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            return Block.Code(content: modified, language: language)
        }
        if codeRegexTab.numberOfMatchesInString(stripped, options: [], range: fullString) > 0 {
            let modified = ("\n" + stripped).stringByReplacingOccurrencesOfString("\n\t", withString: "\n").stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            return Block.Code(content: modified, language: language)
        }
        codeRegexFences.enumerateMatchesInString(stripped, options: [], range: fullString) { (result, _, _) in
            if let result = result {
                if ((result.rangeAtIndex(2).location != NSNotFound) && (result.rangeAtIndex(2).length > 0)) {
                    language = stripped.substringWithRange(result.rangeAtIndex(2))!
                }
                if result.rangeAtIndex(3).location != NSNotFound {
                    resultBlock = Block.Code(content: stripped.substringWithRange(result.rangeAtIndex(3))!, language: language)
                }
            }
        }
        if resultBlock != nil {
            return resultBlock!
        }

        // Identify quote
        let quoteRegex = try! NSRegularExpression(pattern: "(^[ ]{0,3}[>]+[ \\t]*)|(\\n[ ]{0,3}[>]+[ \\t]*)", options: self.regexOptions)
        if quoteRegex.numberOfMatchesInString(stripped, options: [], range: fullString) > 0 {
            let modified = quoteRegex.stringByReplacingMatchesInString(stripped, options: [], range: fullString, withTemplate: "\n").stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            return Block.Quote(content: modified)
        }
        
        // Everything else is just a paragraph
        return Block.Paragraph(content: stripped)
    }
    
    // MARK: - Block content recursive parsers
    
    func renderBlock(block: Block) -> ContentNode {
        switch (block) {
        case .Heading(let level, let content):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .Heading(level: level))
        case .UnorderedList(let content):
            let items = self.splitUnorderedListItems(content)
            return ContentNode(children: items, type: .UnorderedList)
        case .OrderedList(let content):
            let items = self.splitOrderedListItems(content)
            return ContentNode(children: items, type: .OrderedList)
        case .Code(let content, let language):
            return ContentNode(children: [ContentNode.init(text: content)], type: .CodeBlock(language: language))
        case .Paragraph(let content):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .Paragraph)
        case .Quote(let content):
            let preprocessed = self.parseContent(content)
            return ContentNode(children: preprocessed, type: .Quote)
        }
    }
    
    func parseContent(string: String) -> [ContentNode] {
        let trimRegex = try! NSRegularExpression(pattern: "\\n[ ]{0,3}", options: self.regexOptions)
        let fullString = NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        let trimmedString = trimRegex.stringByReplacingMatchesInString(string, options: [], range: fullString, withTemplate: "\n")
        
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
        
        if let t = tokens where t.count > 1 {
            var newTokens:[ContentNode] = []
            for token in t {
                if case .PlainText = token.type {
                    let subTokens = self.parseContent(token.text)
                    if subTokens.count > 0 {
                        newTokens.appendContentsOf(subTokens)
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
    
    func splitUnorderedListItems(string: String) -> [ContentNode] {
        var tokens = [ContentNode]()
        let paddedString = string + "\n"
        let fullString = NSMakeRange(0, paddedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let splitListRegex = try! NSRegularExpression(pattern: "([ ]{0,3}[\\-*+][^\\-*+]([^\\n]*\\n([ \\t]+[^\\n]+\\n)+))|([ ]{0,3}[\\-*+][^\\-*+]([^\\n]*)\\n)", options: self.regexOptions)
        let matches = splitListRegex.matchesInString(paddedString, options: [], range: fullString)
        for index in 0..<matches.count {
            let match = matches[index]
            
            if let multilineItem = paddedString.substringWithRange(match.rangeAtIndex(2)) where multilineItem.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                var result:[ContentNode] = []
                
                for block in self.splitBlocksByIndent(multilineItem) {
                    result.append(self.renderBlock(block))
                }
                
                tokens.append(ContentNode.init(children: result, type: .UnorderedListItem))
            }
            if let singleLineItem = paddedString.substringWithRange(match.rangeAtIndex(5)) where singleLineItem.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                let node = self.parseContent(singleLineItem)
                tokens.append(ContentNode.init(children: node, type: .UnorderedListItem))
            }
        }
        return tokens
    }

    func splitOrderedListItems(string: String) -> [ContentNode] {
        var tokens = [ContentNode]()
        let paddedString = string + "\n"
        let fullString = NSMakeRange(0, paddedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let splitListRegex = try! NSRegularExpression(pattern: "([ ]{0,3}[0-9a-z]+[.\\)][ \\t]*([^\\n]*\\n([ \\t]+[^\\n]+\\n)+))|([ ]{0,3}[0-9a-z]+[.\\)][ \\t]*([^\\n]*)\\n)", options: self.regexOptions)
        let matches = splitListRegex.matchesInString(paddedString, options: [], range: fullString)
        for index in 0..<matches.count {
            let match = matches[index]
            
            if let multilineItem = paddedString.substringWithRange(match.rangeAtIndex(2)) where multilineItem.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                var result:[ContentNode] = []
                
                for block in self.splitBlocksByIndent(multilineItem) {
                    result.append(self.renderBlock(block))
                }
                
                tokens.append(ContentNode.init(children: result, type: .OrderedListItem(index: index + 1)))
            }
            if let singleLineItem = paddedString.substringWithRange(match.rangeAtIndex(5)) where singleLineItem.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                let node = self.parseContent(singleLineItem)
                tokens.append(ContentNode.init(children: node, type: .OrderedListItem(index: index + 1)))
            }
        }
        return tokens
    }
    
    // MARK: Inline content parsers

    func parseInlineCode(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        
        // case InlineCode
        let inlineCodeRegex = try! NSRegularExpression(pattern: "`([^`\\n]+)`", options: self.regexOptions)
        inlineCodeRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .InlineCode))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }
    
    func parseStrongText(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case StrongText
        let strongTextRegex = try! NSRegularExpression(pattern: "[\\*_]{2}([^\\*_\\n]+)[\\*_]{2}", options: self.regexOptions)
        strongTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .StrongText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }
    
    func parseEmphasizedText(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case EmphasizedText
        let emTextRegex = try! NSRegularExpression(pattern: "[\\*_]{1}([^\\*_\\n]+)[\\*_]{1}", options: self.regexOptions)
        emTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .EmphasizedText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseDeletedText(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()

        // case DeletedText
        let delTextRegex = try! NSRegularExpression(pattern: "[~]{2}([^~\\n]+)[~]{2}", options: self.regexOptions)
        delTextRegex.tokenizeString(string) { (token, match) in
            if !match {
                tokens.append(ContentNode.init(text: token))
            } else {
                let textNode = ContentNode.init(text: token)
                tokens.append(ContentNode.init(children: [textNode], type: .DeletedText))
            }
        }

        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseLinks(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        let fullString = NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))

        let linkRegex = try! NSRegularExpression(pattern: "\\[([^\\]]*)\\]\\(((#|[0-9a-z]+://)[^)\\n]*)\\)", options: self.regexOptions)
        let matches = linkRegex.matchesInString(string, options: [], range: fullString)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substringWithRange(string.range(lastSplitPoint, end:match.range.location)!)
                if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    tokens.append(ContentNode.init(text: t))
                }
                // the token match
                let textNode = ContentNode.init(text: string.substringWithRange(match.rangeAtIndex(1))!)
                tokens.append(ContentNode.init(children: [textNode], type: .Link(location: string.substringWithRange(match.rangeAtIndex(2))!)))
            }
            
            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substringWithRange(string.range(lastSplitPoint, end:string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))!)
            if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                tokens.append(ContentNode.init(text: t))
            }
        }
        
        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

    func parseImages(string: String) -> [ContentNode]? {
        var tokens = [ContentNode]()
        let fullString = NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        
        let linkRegex = try! NSRegularExpression(pattern: "!\\[([^\\]]*)\\]\\(([a-z0-9]+://[^)\\n]*)\\)", options: self.regexOptions)
        let matches = linkRegex.matchesInString(string, options: [], range: fullString)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substringWithRange(string.range(lastSplitPoint, end:match.range.location)!)
                if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    tokens.append(ContentNode.init(text: t))
                }
                // the token match
                let textNode = ContentNode.init(text: string.substringWithRange(match.rangeAtIndex(1))!)
                tokens.append(ContentNode.init(children: [textNode], type: .Image(location: string.substringWithRange(match.rangeAtIndex(2))!)))
            }
            
            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substringWithRange(string.range(lastSplitPoint, end:string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))!)
            if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                tokens.append(ContentNode.init(text: t))
            }
        }
        
        if tokens.count > 0 {
            return tokens
        }
        return nil
    }

}

