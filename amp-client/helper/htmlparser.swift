//
//  nsattributedString+html5.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 18/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation
import html5parser
import Markdown

class HTMLParser {
    private let tokens: [HTML5Token]
    private var formatStack = [FormatStackItem]()
    
    private struct FormatStackItem {
        var tagName:String
        var styleDict: [String: AnyObject]
    }

    init(html: String) {
        self.tokens = HTML5Tokenizer(htmlString: html).tokenize()
    }
    
    func renderAttributedString(style: AttributedStringStyling) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var counters = [Int]()
        var depth = 0
        
        self.formatStack.removeAll()
        self.formatStack.append(FormatStackItem(tagName: "root", styleDict: style.paragraph.makeAttributeDict()))
        
        for token in self.tokens {
            switch token {
            case .StartTag(let name, let selfClosing, let attributes):
                guard let name = name where !selfClosing else {
                    continue
                }
                self.pushFormat(style, tagName: name, attributes: attributes, nestingDepth: depth)
                
                switch name {
                case "li":
                    if self.getListContext() == "ul" {
                        result.appendAttributedString(NSAttributedString(string: "\n• ", attributes: style.unorderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                    }
                    if self.getListContext() == "ol"  {
                        let counter = counters.popLast()!
                        result.appendAttributedString(NSAttributedString(string: "\n\(counter). ", attributes: style.orderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                        counters.append(counter + 1)
                    }
                    continue
                case "ol", "ul":
                    depth++
                    counters.append(1)
                default:
                    break
                }
                if result.string.characters.count > 0 && self.isBlock(name) {
                    result.appendAttributedString(NSAttributedString(string: "\n", attributes: formatStack.last!.styleDict))
                }
                
            case .EndTag(let name):
                guard let name = name else {
                    continue
                }
                self.popFormat(name)
                
                switch name {
                case "ol", "ul":
                    result.appendAttributedString(NSAttributedString(string: "\n", attributes: formatStack.last!.styleDict))
                    depth--
                    counters.popLast()
                case "li":
                    continue
                default:
                    break
                }
                
                if !result.string.hasSuffix(" ") {
                    result.appendAttributedString(NSAttributedString(string: " ", attributes: formatStack.last!.styleDict))
                }
                
                
            case .Text(let data):
                guard let data = data else {
                    continue
                }
                let attribs = formatStack.last!.styleDict
                var stripped = data
                if formatStack.last!.tagName != "pre" {
                    stripped = data.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    stripped = stripped.stringByReplacingOccurrencesOfString("\n", withString: " ")
                }
                if result.string.characters.count > 0 && !result.string.hasSuffix(" ") && !result.string.hasSuffix("\n") {
                    stripped = " \(stripped)"
                }
                let string = NSAttributedString(string: stripped, attributes: attribs)
                result.appendAttributedString(string)

            default:
                continue
            }
        }
        
        return result
    }
    
    func renderText() -> String {
        var result = String()
        var counters = [Int]()
        var depth = 0

        var lastTagName = "root"
        var listContext = [String]()
        listContext.append("none")
        
        for token in self.tokens {
            switch token {
            case .StartTag(let name, let selfClosing, let attributes):
                guard let name = name where !selfClosing else {
                    continue
                }
                lastTagName = name
                
                switch name {
                case "li":
                    if listContext.last! == "ul" {
                        result.appendContentsOf("\n")
                        for _ in 0..<depth {
                            result.appendContentsOf("    ")
                        }
                        result.appendContentsOf("- ")
                    }
                    if listContext.last! == "ol"  {
                        let counter = counters.popLast()!
                        result.appendContentsOf("\n")
                        for _ in 0..<depth {
                            result.appendContentsOf("    ")
                        }
                        result.appendContentsOf("\(counter). ")
                        counters.append(counter + 1)
                    }
                    continue
                case "ol", "ul":
                    listContext.append(name)
                    depth++
                    counters.append(1)
                default:
                    break
                }
                if result.characters.count > 0 && self.isBlock(name) {
                    result.appendContentsOf("\n")
                }
                
            case .EndTag(let name):
                guard let name = name else {
                    continue
                }
                
                switch name {
                case "ol", "ul":
                    listContext.popLast()
                    result.appendContentsOf("\n")
                    depth--
                    counters.popLast()
                    continue
                case "li":
                    continue
                default:
                    break
                }
                
                if !result.hasSuffix(" ") {
                    result.appendContentsOf(" ")
                }
                
                
            case .Text(let data):
                guard let data = data else {
                    continue
                }
                var stripped = data
                if lastTagName != "pre" {
                    stripped = data.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                    stripped = stripped.stringByReplacingOccurrencesOfString("\n", withString: " ")
                }
                if result.characters.count > 0 && !result.hasSuffix(" ") && !result.hasSuffix("\n") {
                    result.appendContentsOf(" ")
                }
                result.appendContentsOf(stripped)
                
            default:
                continue
            }
        }
        
        return result
    }
    
    private func pushFormat(style: AttributedStringStyling, tagName: String, attributes: [String:String]?, nestingDepth: Int) {
        switch tagName {
        case "h1":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[1].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h2":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[2].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h3":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[3].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h4":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[4].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h5":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[5].makeAttributeDict(nestingDepth: nestingDepth)))
        case "ul":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.unorderedList.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .ExcludeFont)))
        case "ol":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.orderedList.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .ExcludeFont)))
        case "li":
            if self.getListContext() == "ul" {
                self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.unorderedListItem.makeAttributeDict(nestingDepth: nestingDepth)))
            }
            if self.getListContext() == "ol" {
                self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.orderedListItem.makeAttributeDict(nestingDepth: nestingDepth)))
            }
        case "pre":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.codeBlock.makeAttributeDict(nestingDepth: nestingDepth)))
        case "p":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.paragraph.makeAttributeDict(nestingDepth: nestingDepth)))
        case "blockquote":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.quoteBlock.makeAttributeDict(nestingDepth: nestingDepth)))

        
        case "strong":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.strongText.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .FontOnly)))
        case "b":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.strongText.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .FontOnly)))
        case "em":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.emphasizedText.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .FontOnly)))
        case "i":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.emphasizedText.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .FontOnly)))
        case "del":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.deletedText.makeAttributeDict(nestingDepth: nestingDepth)))
        case "code":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.inlineCode.makeAttributeDict(nestingDepth: nestingDepth)))
        case "a":
            guard attributes != nil,
                  let href = attributes!["href"] else {
                break
            }
            var linkStyle = style.link.makeAttributeDict(nestingDepth: nestingDepth)
            linkStyle[NSLinkAttributeName] = href
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: linkStyle))
        default:
            break
        }
    }
    
    private func popFormat(tagName: String) {
        if self.formatStack.last!.tagName == tagName {
            self.formatStack.popLast()
        } else {
            let tagIsBlock = self.isBlock(tagName)
            let lastTagIsBlock = self.isBlock(self.formatStack.last!.tagName)

            if tagIsBlock {
                // search upwards in stack
                var lastFound = 0
                for (index, item) in self.formatStack.enumerate() {
                    if item.tagName == tagName {
                        lastFound = index
                    }
                }
                if lastFound > 0 {
                    for _ in 0..<(self.formatStack.count - lastFound) {
                        self.formatStack.popLast()
                    }
                }
            }
            if lastTagIsBlock && !tagIsBlock {
                return // ignore
            }
            if !lastTagIsBlock && !tagIsBlock {
                return // ignore
            }
        }
    }
    
    private func isBlock(tagName: String) -> Bool {
        switch tagName {
        case "h1", "h2", "h3", "h4", "h5", "ul", "ol", "li", "pre", "p", "bockquote":
            return true
        case "strong", "b", "em", "i", "del", "code", "a":
            return false
        default:
            return false
        }
    }
    
    private func getListContext() -> String {
        let stack = self.formatStack.reverse()
        for item in stack {
            if item.tagName == "ol" || item.tagName == "ul" {
                return item.tagName
            }
        }
        return "none"
    }
}