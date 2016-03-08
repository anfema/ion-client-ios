//
//  nsattributedString+html5.swift
//  ion-client
//
//  Created by Johannes Schriewer on 18/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation
import html5tokenizer
import Markdown

public class HTMLParser {
    private let tokens: [HTML5Token]
    private var formatStack = [FormatStackItem]()
    
    private struct FormatStackItem {
        var tagName:String
        var styleDict: [String: AnyObject]
    }

    public init(html: String) {
        self.tokens = HTML5Tokenizer(htmlString: html).tokenize()
    }
    
    public func renderAttributedString(style: AttributedStringStyling) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var counters = [Int]()
        var depth = 0
        
        self.formatStack.removeAll()
        self.formatStack.append(FormatStackItem(tagName: "root", styleDict: style.paragraph.makeAttributeDict()))
        
        for token in self.tokens {
            switch token {
            case .StartTag(let name, let selfClosing, let attributes):
                guard let name = name else {
                    continue
                }
                if selfClosing {
                    if name == "br" {
                        result.appendAttributedString(NSAttributedString(string: "\u{2028}", attributes: formatStack.last!.styleDict))
                    } else {
                        continue
                    }
                }
                
                if name == "p" && self.formatStack.last!.tagName == "blockquote" {
                    self.pushFormat(style, tagName: "blockquote", attributes: attributes, nestingDepth: depth)
                } else {
                    self.pushFormat(style, tagName: name, attributes: attributes, nestingDepth: depth)
                }
                
                if self.isBlock(name) {
                    result.appendAttributedString(NSAttributedString(string: "\n", attributes: formatStack.last!.styleDict))
                }
                if name == "p" || name == "pre" {
                    if !result.string.hasSuffix("\n\n") {
                        result.appendAttributedString(NSAttributedString(string: "\n", attributes: formatStack.last!.styleDict))
                    }
                }

                
                switch name {
                case "li":
                    if self.getListContext() == "ul" {
                        result.appendAttributedString(NSAttributedString(string: "•\t", attributes: style.unorderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                    }
                    if self.getListContext() == "ol"  {
                        let counter = counters.popLast()!
                        result.appendAttributedString(NSAttributedString(string: "\(counter).\t", attributes: style.orderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                        counters.append(counter + 1)
                    }
                    continue
                case "ol", "ul":
                    depth += 1
                    counters.append(1)
                case "br":
                    result.appendAttributedString(NSAttributedString(string: "\u{2028}", attributes: formatStack.last!.styleDict))
                default:
                    break
                }
                
            case .EndTag(let name):
                guard let name = name else {
                    continue
                }
                let oldFormat = self.popFormat(name)
                
                switch name {
                case "ol", "ul":
                    depth -= 1
                    counters.popLast()
                case "li":
                    continue
                default:
                    break
                }
                
                if !result.string.hasSuffix(" ") && !result.string.hasSuffix("\n")  && !result.string.hasSuffix("\t") && !result.string.hasSuffix("\u{2028}") && !result.string.hasSuffix("\u{2029}") {
                    let a = (oldFormat != nil) ? oldFormat!.styleDict : formatStack.last!.styleDict
                    result.appendAttributedString(NSAttributedString(string: " ", attributes: a))
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
                    stripped = stripped.stringByReplacingOccurrencesOfString("\u{2028}", withString: " ")
                    stripped = stripped.stringByReplacingOccurrencesOfString("\u{2029}", withString: " ")
                }
                if stripped.characters.count == 0 {
                    continue
                }
                if result.string.characters.count > 0 && !result.string.hasSuffix(" ") && !result.string.hasSuffix("\n")  && !result.string.hasSuffix("\t") && !result.string.hasSuffix("\u{2028}") && !result.string.hasSuffix("\u{2029}") {
                    stripped = " \(stripped)"
                }
                let string = NSAttributedString(string: stripped, attributes: attribs)
                result.appendAttributedString(string)

            default:
                continue
            }
        }
        
        while true {
            if let rng = result.string.rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), options: .BackwardsSearch) where rng.endIndex == result.string.endIndex {
                let start = result.string.startIndex.distanceTo(rng.startIndex)
                let len = rng.startIndex.distanceTo(rng.endIndex)
                result.replaceCharactersInRange(NSMakeRange(start, len), withAttributedString: NSAttributedString())
            } else {
                break
            }
        }

        while true {
            if let rng = result.string.rangeOfCharacterFromSet(NSCharacterSet.whitespaceAndNewlineCharacterSet(), options: NSStringCompareOptions()) where rng.startIndex == result.string.startIndex {
                let start = result.string.startIndex.distanceTo(rng.startIndex)
                let len = rng.startIndex.distanceTo(rng.endIndex)
                result.replaceCharactersInRange(NSMakeRange(start, len), withAttributedString: NSAttributedString())
            } else {
                break
            }
        }

        return result
    }
    
    func renderText() -> String {
        var result = String()
        var counters = [Int]()
        var depth = 0

        var lastTagName = "root"
        var listContext = ["none"]
        
        for token in self.tokens {
            switch token {
            case .StartTag(let name, let selfClosing, _):
                guard let name = name else {
                    continue
                }
                if selfClosing {
                    if name == "br" {
                        result.appendContentsOf("\n")
                    } else {
                        continue
                    }
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
                    depth += 1
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
                    depth -= 1
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
    
    private func popFormat(tagName: String) -> FormatStackItem? {
        if self.formatStack.last!.tagName == tagName {
            return self.formatStack.popLast()
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
                        return self.formatStack.popLast()
                    }
                }
            }
            if lastTagIsBlock && !tagIsBlock {
                return nil // ignore
            }
            if !lastTagIsBlock && !tagIsBlock {
                return nil // ignore
            }
        }
        return nil
    }
    
    private func isBlock(tagName: String) -> Bool {
        switch tagName {
        case "h1", "h2", "h3", "h4", "h5", "ul", "ol", "li", "pre", "p", "blockquote":
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