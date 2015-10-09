//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson
import Markdown

public class AMPTextContent : AMPContent {
    public var mimeType:String = "text/plain"  /// mime type of the contained text (usually one of: text/plain, text/html, text/markdown)
    public var multiLine:Bool  = false         /// multi line hint

    private var text:String!                   /// text, private because of conversion functions
    
    /// Initialize text content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized text content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["is_multiline"] != nil) && (dict["text"] != nil),
            case .JSONString(let mimeType) = dict["mime_type"]!,
            case .JSONBoolean(let multiLine) = dict["is_multiline"]!,
            case .JSONString(let text) = dict["text"]! else {
                throw AMPError.Code.InvalidJSON(json)
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
    public func attributedString() -> NSAttributedString? {
        // TODO: Setup default styling
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
            return MDParser(markdown: self.text).render().renderAttributedString(AttributedStringStyling())
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

// TODO: Support HTML text on page level
// TODO: Support Attributed string on page level
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
}
