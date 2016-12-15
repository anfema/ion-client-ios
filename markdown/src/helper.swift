//
//  helper.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

extension String {
    func rangeFromNSRange(_ nsRange : NSRange) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: nsRange.location, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: nsRange.length, limitedBy: utf16.endIndex) else
        {
            return nil
        }
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    // FIXME: Is this dead code?
    func range(_ start: Int, length: Int) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: start, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: length, limitedBy: utf16.endIndex) else
        {
            return nil
        }
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }

    func range(_ start: Int, end: Int) -> Range<String.Index>? {
        guard let from16 = utf16.index(utf16.startIndex, offsetBy: start, limitedBy: utf16.endIndex),
            let to16 = utf16.index(from16, offsetBy: end - start, limitedBy: utf16.endIndex) else
        {
            return nil
        }
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func substringWithRange(_ range: NSRange) -> String? {
        if let rng = self.rangeFromNSRange(range) {
            return self.substring(with: rng)
        }
        return nil
    }
}

extension NSRegularExpression {
    
    func tokenizeString(_ string: String, options: NSRegularExpression.MatchingOptions, range: NSRange, callback:((_ token: String, _ match: Bool) -> Void)) {
        let matches = self.matches(in: string, options: options, range: range)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substring(with: string.range(lastSplitPoint, end:match.range.location)!)
                if t.characters.count > 0 {
                    callback(t, false)
                }
                // the token match
                callback(string.substringWithRange(match.rangeAt(1))!, true)
            }

            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substring(with: string.range(lastSplitPoint, end:string.characters.count)!)
            if t.characters.count > 0 {
                callback(t, false)
            }
        }
    }
    
    func tokenizeString(_ string: String, callback:((_ token: String, _ match: Bool) -> Void)) {
        let fullString = NSMakeRange(0, string.characters.count)
        self.tokenizeString(string, options: [], range: fullString, callback: callback)
    }
}
