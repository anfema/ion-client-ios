//
//  tokens.swift
//  html5tokenizer
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

public enum HTML5Token {
    case docType(name: String?, publicID: String?, systemID: String?, forceQuirks: Bool)
    case startTag(name: String?, selfClosing: Bool, attributes: [String: String]?)
    case endTag(name: String?)
    case comment(data: String?)
    case text(data: String?)
    case eof
}

extension HTML5Token: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {

        case .docType(let name, let publicID, let systemID, let forceQuirks):
            return "<HTML5Token DOCTYPE, name: \(name ?? ""), public: \(publicID ?? ""), system: \(systemID ?? ""), forceQuirks: \(forceQuirks)>"

        case .startTag(let name, let selfClosing, let attributes):
            var result = "<HTML5Token start tag '\(name!)', self closing: \(selfClosing)"
            if let attributes = attributes {
                result.append(", attributes: {\n")
                for (key, value) in attributes {
                    result.append("    '\(key)' = '\(value)',\n")
                }
                result.append("}")
            }
            result.append(">")
            return result

        case .endTag(let name):
            return "<HTML5Token end tag '\(name!)'>"

        case .comment(let data):
            if let data = data {
                var string = data.replacingOccurrences(of: "\n", with: "\\n")
                if data.count > 30 {
                    string = string[...data.index(data.startIndex, offsetBy: 30)] + "…"
                }
                return "<HTML5Token comment '\(string)'>"
            }
            return "<HTML5Token comment, empty>"

        case .text(let data):
            if let data = data {
                var string = data.replacingOccurrences(of: "\n", with: "\\n")
                if data.count > 30 {
                    string = string[...data.index(data.startIndex, offsetBy: 30)] + "…"
                }
                return "<HTML5Token text '\(string)'>"
            }
            return "<HTML5Token text, empty>"

        case .eof:
            return "<HTML5Token EOF>"
        }
    }
}

extension HTML5Token: CustomStringConvertible {
    public var description: String {
        switch self {

        case .docType(let name, let publicID, let systemID, _):
            return "<!DOCTYPE \(name ?? "") \"\(publicID ?? "")\" \"\(systemID ?? "")\">"

        case .startTag(let name, let selfClosing, let attributes):
            var result = "<\(name ?? "")"
            if let attributes = attributes {
                result.append(" ")
                for (key, value) in attributes {
                    result.append(" \(key)=\"\(value)\"")
                }
            }
            if selfClosing {
                result.append("/")
            }
            result.append(">")
            return result

        case .endTag(let name):
            return "</\(name ?? "")>"

        case .comment(let data):
            return "<!-- \(data ?? "") -->"

        case .text(let data):
            return "\(data ?? "")"

        case .eof:
            return ""
        }
    }
}
