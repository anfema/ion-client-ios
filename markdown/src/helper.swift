//
//  helper.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

extension String {
    func rangeFromNSRange(nsRange : NSRange) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(nsRange.location, limit: utf16.endIndex)
        let to16 = from16.advancedBy(nsRange.length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func range(start: Int, length: Int) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(start, limit: utf16.endIndex)
        let to16 = from16.advancedBy(length, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }

    func range(start: Int, end: Int) -> Range<String.Index>? {
        let from16 = utf16.startIndex.advancedBy(start, limit: utf16.endIndex)
        let to16 = from16.advancedBy(end - start, limit: utf16.endIndex)
        if let from = String.Index(from16, within: self),
            let to = String.Index(to16, within: self) {
                return from ..< to
        }
        return nil
    }
    
    func substringWithRange(range: NSRange) -> String? {
        if let rng = self.rangeFromNSRange(range) {
            return self.substringWithRange(rng)
        }
        return nil
    }
}

extension NSRegularExpression {
    
    func tokenizeString(string: String, options: NSMatchingOptions, range: NSRange, callback:((token: String, match: Bool) -> Void)) {
        let matches = self.matchesInString(string, options: options, range: range)
        if matches.count > 0 {
            for index in 0..<matches.count {
                let match = matches[index]
                
                var lastSplitPoint = 0
                if index > 0 {
                    let lastMatch = matches[index - 1]
                    lastSplitPoint = lastMatch.range.location + lastMatch.range.length
                }
                // text from last match to this match
                let t = string.substringWithRange(string.range(lastSplitPoint, end:match.range.location)!)
                if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                    callback(token: t, match: false)
                }
                // the token match
                callback(token: string.substringWithRange(match.rangeAtIndex(1))!, match: true)
            }

            // remaining text
            let lastSplitPoint = matches.last!.range.location + matches.last!.range.length
            let t = string.substringWithRange(string.range(lastSplitPoint, end:string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))!)
            if t.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) > 0 {
                callback(token: t, match: false)
            }
        }
    }
    
    func tokenizeString(string: String, callback:((token: String, match: Bool) -> Void)) {
        let fullString = NSMakeRange(0, string.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
        self.tokenizeString(string, options: [], range: fullString, callback: callback)
    }
}