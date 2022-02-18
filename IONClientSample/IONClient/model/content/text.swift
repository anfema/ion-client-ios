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


/// Text content, may be rendered in different markup
open class IONTextContent: IONContent {

    /// MIME type of the contained text (usually one of: text/plain, text/html, text/markdown)
    open var mimeType: String = "text/plain"

    /// Multi line hint
    open var multiLine: Bool = false

    /// Text, private because of conversion functions
    fileprivate var text: String


    /// Initialize text content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized text content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawMimeType   = dict["mime_type"],
            let rawIsMultiline  = dict["is_multiline"],
            let rawText         = dict["text"],
            case .jsonString(let mimeType)      = rawMimeType,
            case .jsonBoolean(let multiLine)    = rawIsMultiline,
            case .jsonString(let text)          = rawText else {
                throw IONError.invalidJSON(json)
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
    open func htmlText() -> String? {
        // TODO: Write tests for htmlText() function in TextContent
        var text: String = ""
        switch self.mimeType {
        case "text/html":
            text = self.text
        case "text/markdown":
            text = MDParser(markdown: self.text).render().renderHTMLFragment()
        case "text/plain":
            text = self.text.replacingOccurrences(of: "\n", with: "<br>\n")
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
    open func attributedString() -> NSAttributedString? {
        // TODO: Write tests for attributedString() function in TextContent
        switch self.mimeType {
        case "text/html":
            return HTMLParser(html: self.text).renderAttributedString(using: ION.config.stringStyling)
        case "text/markdown":
            return MDParser(markdown: self.text).render().renderAttributedString(usingStyle: ION.config.stringStyling)
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
    open func plainText() -> String? {
        // TODO: Write tests for plainText() function in TextContent (probably we need more test-data for this)
        switch self.mimeType {
        case "text/plain":
            return self.text
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
    public func text(_ name: String, atPosition position: Int = 0) -> Result<String> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let textContent as IONTextContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let text = textContent.plainText() else {
            return .failure(IONError.outletEmpty)
        }

        return .success(text)
    }


    /// Fetch plaintext string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func text(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<String>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.text(name, atPosition: position))
        }

        return self
    }


    /// Fetch html string for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `String` if the outlet is a text outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func html(_ name: String, atPosition position: Int = 0) -> Result<String> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let textContent as IONTextContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let text = textContent.htmlText() else {
            return .failure(IONError.outletEmpty)
        }

        return .success(text)
    }


    /// Fetch html string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func html(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<String>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.html(name, atPosition: position))
        }

        return self
    }


    /// Fetch attributed string for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing a `NSAttributedString` if the outlet is a text outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func attributedString(_ name: String, atPosition position: Int = 0) -> Result<NSAttributedString> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let textContent as IONTextContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let text = textContent.attributedString() else {
            return .failure(IONError.outletEmpty)
        }

        return .success(text)
    }


    /// Fetch attributed string for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the text outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSAttributedString` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func attributedString(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<NSAttributedString>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.attributedString(name, atPosition: position))
        }

        return self
    }
}


public extension Content {

    /// Provides a text content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func textContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONTextContent? {
        return self.content(identifier, at: position)
    }


    func textContents(_ identifier: OutletIdentifier) -> [IONTextContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONTextContent] ?? nil)
    }


     func text(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {
        return textContent(identifier, at: position)?.plainText()
    }


    func attributedText(_ identifier: OutletIdentifier, at position: Position = 0) -> NSAttributedString? {
        return textContent(identifier, at: position)?.attributedString()
    }


    func htmlText(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {
        return textContent(identifier, at: position)?.htmlText()
    }
}
