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

    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }

    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }

    subscript (range: NSRange) -> String? {
        if let rng = self.rangeFromNSRange(range) {
            return String(self[rng])
        }
        return nil
    }
}

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
                let t = string[lastSplitPoint..<match.range.location]
                if t.count > 0 {
                    callback(t, false)
                }
                // the token match
                callback(string[match.range(at: 1)]!, true)
            }

            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string[lastSplitPoint..<string.count]
            if t.count > 0 {
                callback(t, false)
            }
        }
    }
    
    func tokenizeString(_ string: String, callback:((_ token: String, _ match: Bool) -> Void)) {
        let fullString = NSMakeRange(0, string.count)
        self.tokenizeString(string, options: [], range: fullString, callback: callback)
    }
}
