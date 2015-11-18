//
//  tokens.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

public enum HTML5Token {
    case DocType(name:String?, publicID:String?, systemID:String?, forceQuirks:Bool)
    case StartTag(name:String?, selfClosing: Bool, attributes:[String:String]?)
    case EndTag(name:String?)
    case Comment(data:String?)
    case Text(data:String?)
    case EOF
}

extension HTML5Token: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
            
        case .DocType(let name, let publicID, let systemID, let forceQuirks):
            return "<HTML5Token DOCTYPE, name: \(name!), public: \(publicID), system: \(systemID), forceQuirks: \(forceQuirks)>"
            
        case .StartTag(let name, let selfClosing, let attributes):
            var result = "<HTML5Token start tag '\(name!)', self closing: \(selfClosing)"
            if let attributes = attributes {
                result.appendContentsOf(", attributes: {\n")
                for (key, value) in attributes {
                    result.appendContentsOf("    '\(key)' = '\(value)',\n")
                }
                result.appendContentsOf("}")
            }
            result.appendContentsOf(">")
            return result
            
        case .EndTag(let name):
            return "<HTML5Token end tag '\(name!)'>"
            
        case .Comment(let data):
            if let data = data {
                var string = data.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
                if data.characters.count > 30 {
                    string = string.substringToIndex(data.startIndex.advancedBy(30)) + "…"
                }
                return "<HTML5Token comment '\(string)'>"
            }
            return "<HTML5Token comment, empty>"

        case .Text(let data):
            if let data = data {
                var string = data.stringByReplacingOccurrencesOfString("\n", withString: "\\n")
                if data.characters.count > 30 {
                    string = string.substringToIndex(data.startIndex.advancedBy(30)) + "…"
                }
                return "<HTML5Token text '\(string)'>"
            }
            return "<HTML5Token text, empty>"

        case .EOF:
            return "<HTML5Token EOF>"
        }
    }
}

extension HTML5Token: CustomStringConvertible {
    public var description: String {
        switch self {
            
        case .DocType(let name, let publicID, let systemID, _):
            return "<!DOCTYPE \(name) \"\(publicID)\" \"\(systemID)\">"
            
        case .StartTag(let name, let selfClosing, let attributes):
            var result = "<\(name)"
            if let attributes = attributes {
                result.appendContentsOf(" ")
                for (key, value) in attributes {
                    result.appendContentsOf(" \(key)=\"\(value)\"")
                }
            }
            if selfClosing {
                result.appendContentsOf("/")
            }
            result.appendContentsOf(">")
            return result
            
        case .EndTag(let name):
            return "</\(name)>"
            
        case .Comment(let data):
            return "<!-- \(data) -->"
            
        case .Text(let data):
            return "\(data)"

        case .EOF:
            return ""
        }
    }
}