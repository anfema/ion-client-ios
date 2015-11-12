//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson
import Markdown

/// Text content, may be rendered in different markup
public class AMPTextContent : AMPContent {
    /// mime type of the contained text (usually one of: text/plain, text/html, text/markdown)
    public var mimeType:String = "text/plain"
    
    /// multi line hint
    public var multiLine:Bool  = false

    /// text, private because of conversion functions
    private var text:String!
    
    /// Initialize text content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized text content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["is_multiline"] != nil) && (dict["text"] != nil),
            case .JSONString(let mimeType) = dict["mime_type"]!,
            case .JSONBoolean(let multiLine) = dict["is_multiline"]!,
            case .JSONString(let text) = dict["text"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.multiLine = multiLine
        self.text = text
    }
    
    /// Fetch HTML Representation of the text
    ///
    /// All HTML gets wrapped in a `div` tag with 2 css classes applied:
    /// - `ampcontent`
    /// - `ampcontent__<outlet_name>`
    ///
    /// Available converters:
    /// - html: just wrap in div tag
    /// - plaintext: replace linebreaks with `br` tags and wrap in div
    /// - markdown: convert to html and wrap in div (TODO)
    ///
    /// - Returns: String with HTML encoded text
    // TODO: Write tests for htmlText() function in TextContent
    public func htmlText() -> String? {
        var text: String = ""
        switch (self.mimeType) {
        case "text/html":
            text = self.text
        case "text/markdown":
            text = MDParser(markdown: self.text).render().renderHTMLFragment()
        case "text/plain":
            text = self.text.stringByReplacingOccurrencesOfString("\n", withString: "<br>\n")
        default:
            return nil
        }
        return "<div class=\"ampcontent ampcontent__\(self.outlet)\">\(text)</div>"
    }
    
    /// Fetch NSAttributed String version of the text
    ///
    /// Available converters:
    /// - html: currently very slow
    /// - plaintext: just apply default styling and return
    /// - markdown: try to make best efford representation as attributed string (TODO)
    ///
    /// - Returns: attributed string version of text
    // TODO: Write tests for attributedString() function in TextContent
    public func attributedString() -> NSAttributedString? {
        switch (self.mimeType) {
        case "text/html":
            // FIXME: Speed this up
            if let data = self.text.dataUsingEncoding(NSUTF8StringEncoding) {
                do {
                    return try NSAttributedString(
                        data: data,
                        options: [
                            NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
                            NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
                        ],
                        documentAttributes: nil
                    )
                } catch {
                    return nil
                }
            } else {
                return nil
            }
        case "text/markdown":
            return MDParser(markdown: self.text).render().renderAttributedString(AMP.config.stringStyling)
        case "text/plain":
            return NSAttributedString(string: self.text)
        default:
            return nil
        }
    }
    
    /// Fetch plaintext version of the text
    ///
    /// Available converters:
    /// - html: strip tags, remove linebreaks, add linebreaks for `br` tags, add 2 linebreaks for `div` tags (TODO)
    /// - plaintext: just return text
    /// - markdown: strip markup (asterisk, underscore, links, heading markers) (TODO)
    ///
    /// - Returns: plaintext string of text
    // TODO: Write tests for plainText() function in TextContent (probably we need more test-data for this)
    public func plainText() -> String? {
        switch(self.mimeType) {
        case "text/plain":
            return self.text
        case "text/html":
            // TODO: Strip tags
            return self.text
        case "text/markdown":
            return MDParser(markdown: self.text).render().renderText()
        default:
            // Unknown content type, just assume user wants no alterations
            return self.text
        }
    }
}

/// Text rendering extensions for AMPPage
extension AMPPage {
    
    /// Fetch plaintext string from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: plaintext string if the outlet was a text outlet and the page was already cached, else nil
    public func text(name: String) -> String? {
        if let content = self.outlet(name) {
            if case let content as AMPTextContent = content {
                return content.plainText()
            }
        }
        return nil
    }
    
    /// Fetch plaintext string from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func text(name: String, callback: (String -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPTextContent = content {
                if let text = content.plainText() {
                    callback(text)
                }
            }
        }
        return self
    }
    
    /// Fetch html string from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: html string if the outlet was a text outlet and the page was already cached, else nil
    // TODO: Write tests for page's html function
    public func html(name: String) -> String? {
        if let content = self.outlet(name) {
            if case let content as AMPTextContent = content {
                return content.htmlText()
            }
        }
        return nil
    }
    
    /// Fetch html string from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func html(name: String, callback: (String -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPTextContent = content {
                if let text = content.htmlText() {
                    callback(text)
                }
            }
        }
        return self
    }

    /// Fetch attributed string from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: attribiuted string if the outlet was a text outlet and the page was already cached, else nil
    // TODO: Write tests for page's attributedString function
    public func attributedString(name: String) -> NSAttributedString? {
        if let content = self.outlet(name) {
            if case let content as AMPTextContent = content {
                return content.attributedString()
            }
        }
        return nil
    }
    
    /// Fetch attributed string from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func attributedString(name: String, callback: (NSAttributedString -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPTextContent = content {
                if let text = content.attributedString() {
                    callback(text)
                }
            }
        }
        return self
    }

}
