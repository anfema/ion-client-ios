//
//  content.swift
//  ion-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson
import Markdown
import html5tokenizer

/// Text content, may be rendered in different markup
public class IONTextContent: IONContent {
    /// mime type of the contained text (usually one of: text/plain, text/html, text/markdown)
    public var mimeType:String = "text/plain"
    
    /// multi line hint
    public var multiLine:Bool  = false

    /// text, private because of conversion functions
    private var text:String!
    
    /// Initialize text content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized text content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType = dict["mime_type"], rawIsMultiline = dict["is_multiline"], rawText = dict["text"],
            case .JSONString(let mimeType) = rawMimeType,
            case .JSONBoolean(let multiLine) = rawIsMultiline,
            case .JSONString(let text) = rawText else {
                throw IONError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.multiLine = multiLine
        self.text = text
    }
    
    /// Fetch HTML Representation of the text
    ///
    /// All HTML gets wrapped in a `div` tag with 2 css classes applied:
    ///
    /// - `ioncontent`
    /// - `ioncontent__<outlet_name>`
    ///
    /// Available converters:
    ///
    /// - html: just wrap in div tag
    /// - plaintext: replace linebreaks with `br` tags and wrap in div
    /// - markdown: convert to html and wrap in div
    ///
    /// - returns: String with HTML encoded text
    public func htmlText() -> String? {
        // TODO: Write tests for htmlText() function in TextContent
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
        return "<div class=\"ioncontent ioncontent__\(self.outlet)\">\(text)</div>"
    }
    
    /// Fetch NSAttributed String version of the text
    ///
    /// Available converters:
    ///
    /// - html: currently very slow
    /// - plaintext: just apply default styling and return
    /// - markdown: try to make best efford representation as attributed string
    ///
    /// - returns: attributed string version of text
    public func attributedString() -> NSAttributedString? {
        // TODO: Write tests for attributedString() function in TextContent
        switch (self.mimeType) {
        case "text/html":
            return HTMLParser(html: self.text).renderAttributedString(ION.config.stringStyling)
        case "text/markdown":
            return MDParser(markdown: self.text).render().renderAttributedString(ION.config.stringStyling)
        case "text/plain":
            return NSAttributedString(string: self.text)
        default:
            return nil
        }
    }
    
    /// Fetch plaintext version of the text
    ///
    /// Available converters:
    ///
    /// - html: strip tags, remove linebreaks, add linebreaks for `br` tags, add 2 linebreaks for `p` tags, etc.
    /// - plaintext: just return text
    /// - markdown: strip markup (asterisk, underscore, links, heading markers)
    ///
    /// - returns: plaintext string of text
    public func plainText() -> String? {
        // TODO: Write tests for plainText() function in TextContent (probably we need more test-data for this)
        switch(self.mimeType) {
        case "text/plain":
            return HTMLParser(html: self.text).renderText()
        case "text/html":
            return HTMLParser(html: self.text).renderText()
        case "text/markdown":
            return MDParser(markdown: self.text).render().renderText()
        default:
            // Unknown content type, just assume user wants no alterations
            return self.text
        }
    }
}

/// Text rendering extensions for IONPage
extension IONPage {
    
    /// Fetch plaintext string from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: plaintext string if the outlet was a text outlet and the page was already cached, else nil
    public func text(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        if case let content as IONTextContent = content {
            if let text = content.plainText() {
                return .Success(text)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch plaintext string from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func text(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }

            if case let content as IONTextContent = content {
                if let text = content.plainText() {
                    responseQueueCallback(callback, parameter: .Success(text))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.OutletEmpty))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
    
    /// Fetch html string from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: html string if the outlet was a text outlet and the page was already cached, else nil
    public func html(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        
        if case let content as IONTextContent = content {
            if let text = content.htmlText() {
                return .Success(text)
            } else {
                return .Failure(.OutletEmpty)
            }
        }

        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch html string from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func html(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }

            if case let content as IONTextContent = content {
                if let text = content.htmlText() {
                    responseQueueCallback(callback, parameter: .Success(text))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.OutletEmpty))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }

    /// Fetch attributed string from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: attribiuted string if the outlet was a text outlet and the page was already cached, else nil
    public func attributedString(name: String, position: Int = 0) -> Result<NSAttributedString, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }

        if case let content as IONTextContent = content {
            if let text = content.attributedString() {
                return .Success(text)
            } else {
                return .Failure(.OutletEmpty)
            }
        }

        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch attributed string from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the text object becomes available, will not be called if the outlet
    ///                       is not a text outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func attributedString(name: String, position: Int = 0, callback: (Result<NSAttributedString, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }

            if case let content as IONTextContent = content {
                if let text = content.attributedString() {
                    responseQueueCallback(callback, parameter: .Success(text))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.OutletEmpty))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
}
