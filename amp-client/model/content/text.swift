//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPTextContent : AMPContentBase {
    var mimeType:String = "text/plain"
    var multiLine:Bool  = false
    var text:String!
    
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
    
    public func htmlText() -> String? {
        switch (self.mimeType) {
        case "text/html":
            return self.text
        case "text/markdown":
            // TODO: convert Markdown to HTML
            return self.text
        case "text/plain":
            // FIXME: Wrap somehow?
            return self.text
        default:
            return nil
        }
    }
    
    public func attributedString() -> NSAttributedString? {
        switch (self.mimeType) {
        case "text/html":
            // TODO: Speed this up
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
            // TODO: Parse markdown
            return NSAttributedString(string: self.text)
        case "text/plain":
            return NSAttributedString(string: self.text)
        default:
            return nil
        }
    }
    
    public func plainText() -> String? {
        switch(self.mimeType) {
        case "text/plain":
            return self.text
        case "text/html":
            // TODO: Strip tags
            return self.text
        case "text/markdown":
            // TODO: Strip markup
            return self.text
        default:
            // Unknown content type, just assume user wants no alterations
            return self.text
        }
    }
}

extension AMPPage {
    public func text(name: String) -> String? {
        if let content = self.outlet(name) {
            if case .Text(let txt) = content {
                return txt.plainText()
            }
        }
        return nil
    }
    
    public func text(name: String, callback: (String -> Void)) {
        self.outlet(name) { content in
            if case .Text(let txt) = content {
                if let text = txt.plainText() {
                    callback(text)
                }
            }
        }
    }
}
