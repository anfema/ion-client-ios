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

/// Render HTML to attributed strings
public class HTMLParser {
    private let tokens: [HTML5Token]
    private var formatStack = [FormatStackItem]()
    
    private struct FormatStackItem {
        var tagName: String
        var styleDict: [String: AnyObject]
    }

    /// Initialize with HTML string, instantly runs the tokenizer
    ///
    /// - parameter html: The HTML string to parse
    public init(html: String) {
        self.tokens = HTML5Tokenizer(htmlString: html).tokenize()
    }
    
    /// Render attributed string
    ///
    /// - parameter style: Document style
    /// - returns: `NSAttributedString` for HTML
    public func renderAttributedString(style: AttributedStringStyling) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var counters = [Int]()
        var depth = 0
        
        self.formatStack.removeAll()
        self.formatStack.append(FormatStackItem(tagName: "root", styleDict: style.paragraph.makeAttributeDict()))
        
        for token in self.tokens {
            // there is always at least one FormatStackItem (root) in formatStack.
            guard let lastStackItem = self.formatStack.last else {
                continue
            }
            
            switch token {
            case .StartTag(let name, let selfClosing, let attributes):
                guard let name = name else {
                    continue
                }
                if selfClosing {
                    if name == "br" {
                        result.appendAttributedString(NSAttributedString(string: "\u{2028}", attributes: lastStackItem.styleDict))
                    } else {
                        continue
                    }
                }
                
                if name == "p" && lastStackItem.tagName == "blockquote" {
                    self.pushFormat(style, tagName: "blockquote", attributes: attributes, nestingDepth: depth)
                } else {
                    // Do not allow any formatting inside of heading tags
                    if lastStackItem.tagName.hasPrefix("h") && lastStackItem.tagName.characters.count == 2 {
                        // FIXME: remove this case when the desk editor behaves correctly again
                        continue
                    }
                    self.pushFormat(style, tagName: name, attributes: attributes, nestingDepth: depth)
                }
                
                if self.isBlock(name) {
                    result.appendAttributedString(NSAttributedString(string: "\n", attributes: lastStackItem.styleDict))
                }
                if name == "p" || name == "pre" {
                    if !result.string.hasSuffix("\n\n") {
                        result.appendAttributedString(NSAttributedString(string: "\n", attributes: lastStackItem.styleDict))
                    }
                }

                
                switch name {
                case "li":
                    if self.getListContext() == "ul" {
                        result.appendAttributedString(NSAttributedString(string: "•\t", attributes: style.unorderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                    }
                    if self.getListContext() == "ol"  {
                        guard let counter = counters.popLast() else {
                            continue
                        }
                        
                        result.appendAttributedString(NSAttributedString(string: "\(counter).\t", attributes: style.orderedListItem.makeAttributeDict(nestingDepth: depth - 1)))
                        counters.append(counter + 1)
                    }
                    continue
                case "ol", "ul":
                    depth += 1
                    counters.append(1)
                case "br":
                    result.appendAttributedString(NSAttributedString(string: "\u{2028}", attributes: lastStackItem.styleDict))
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
                    let a = (oldFormat ?? lastStackItem).styleDict
                    result.appendAttributedString(NSAttributedString(string: " ", attributes: a))
                }
                
            case .Text(let data):
                guard let data = data else {
                    continue
                }
                let attribs = lastStackItem.styleDict
                var stripped = data
                if lastStackItem.tagName != "pre" {
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
                let len = rng.startIndex.distanceTo(rng.endIndex)
                let stringLength = (result.string as NSString).length
                result.replaceCharactersInRange(NSMakeRange(stringLength - len, len), withAttributedString: NSAttributedString())
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
    
    /// Render text only version of HTML
    ///
    /// - returns: Plaintext version of HTML stripped of all tags
    public func renderText() -> String {
        var result = String()
        var counters = [Int]()
        var depth = 0

        var lastTagName = "root"
        var listContext = ["none"]
        
        for token in self.tokens {
            // there is always at least one item ("none") in listContext.
            guard let lastListContextItem = listContext.last else {
                continue
            }
            
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
                    if lastListContextItem == "ul" {
                        result.appendContentsOf("\n")
                        for _ in 0..<depth {
                            result.appendContentsOf("    ")
                        }
                        result.appendContentsOf("- ")
                    }
                    if lastListContextItem == "ol"  {
                        guard let counter = counters.popLast() else {
                            continue
                        }
                        
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
    
    private func pushFormat(style: AttributedStringStyling, tagName: String, attributes: [String: String]?, nestingDepth: Int) {
        switch tagName {
        case "h1":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[0].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h2":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[1].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h3":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[2].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h4":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[3].makeAttributeDict(nestingDepth: nestingDepth)))
        case "h5":
            self.formatStack.append(FormatStackItem(tagName: tagName, styleDict: style.heading[4].makeAttributeDict(nestingDepth: nestingDepth)))
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
            guard let attributes = attributes,
                  let href = attributes["href"] else {
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
        guard let lastStackItem = self.formatStack.last else {
            return nil
        }
        
        if lastStackItem.tagName == tagName {
            return self.formatStack.popLast()
        } else {
            let tagIsBlock = self.isBlock(tagName)

            guard tagIsBlock else {
                return nil // ignore
            }
            
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