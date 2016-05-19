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
    
    /// MIME type of the contained text (usually one of: text/plain, text/html, text/markdown)
    public var mimeType: String = "text/plain"
    
    /// Multi line hint
    public var multiLine: Bool = false

    /// Text, private because of conversion functions
    private var text: String
    
    
    /// Initialize text content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized text content object
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType   = dict["mime_type"],
            let rawIsMultiline  = dict["is_multiline"],
            let rawText         = dict["text"],
            case .JSONString(let mimeType)      = rawMimeType,
            case .JSONBoolean(let multiLine)    = rawIsMultiline,
            case .JSONString(let text)          = rawText else {
                throw IONError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.multiLine = multiLine
        self.text = text
    
        try super.init(json: json)
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
    /// - html: Just wrap in div tag
    /// - plaintext: Replace linebreaks with `br` tags and wrap in div
    /// - markdown: Convert to html and wrap in div
    ///
    /// - returns: String with HTML encoded text
    public func htmlText() -> String? {
        // TODO: Write tests for htmlText() function in TextContent
        var text: String = ""
        switch self.mimeType {
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
    /// - html: Currently very slow
    /// - plaintext: Just apply default styling and return
    /// - markdown: Try to make best efford representation as attributed string
    ///
    /// - returns: Attributed string version of text
    public func attributedString() -> NSAttributedString? {
        // TODO: Write tests for attributedString() function in TextContent
        switch self.mimeType {
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
    /// - html: Strip tags, remove linebreaks, add linebreaks for `br` tags, add 2 linebreaks for `p` tags, etc.
    /// - plaintext: Just returns text
    /// - markdown: Strip markup (asterisk, underscore, links, heading markers)
    ///
    /// - returns: Plaintext string of text
    public func plainText() -> String? {
        // TODO: Write tests for plainText() function in TextContent (probably we need more test-data for this)
        switch self.mimeType {
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
    
    /// Fetch plaintext string for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `String` if the outlet is a text outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func text(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        guard case let textContent as IONTextContent = content else {
            return .Failure(.OutletIncompatible)
        }
        
        guard let text = textContent.plainText() else {
            return .Failure(.OutletEmpty)
        }
        
        return .Success(text)
    }
    
    
    /// Fetch plaintext string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func text(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.text(name, position: position))
        }
        
        return self
    }
    
    
    /// Fetch html string for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `String` if the outlet is a text outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func html(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        guard case let textContent as IONTextContent = content else {
            return .Failure(.OutletIncompatible)
        }
        
        guard let text = textContent.htmlText() else {
            return .Failure(.OutletEmpty)
        }

        return .Success(text)
    }
    
    
    /// Fetch html string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func html(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.html(name, position: position))
        }
        
        return self
    }
    

    /// Fetch attributed string for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSAttributedString` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func attributedString(name: String, position: Int = 0) -> Result<NSAttributedString, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }

        guard case let textContent as IONTextContent = content else {
            return .Failure(.OutletIncompatible)
        }

        guard let text = textContent.attributedString() else {
            return .Failure(.OutletEmpty)
        }
        
        return .Success(text)
    }
    
    
    /// Fetch attributed string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSAttributedString` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func attributedString(name: String, position: Int = 0, callback: (Result<NSAttributedString, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.attributedString(name, position: position))
        }
        
        return self
    }
}
