//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

/// DateTime content
public class AMPDateTimeContent : AMPContent {
    /// parsed date
    public var date:NSDate?
    
    /// Initialize datetime content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized datetime content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["datetime"] != nil),
            case .JSONString(let datetime) = dict["datetime"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        fmt.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
        fmt.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
        
        self.date = fmt.dateFromString(datetime)
    }
}

/// Date extension to AMPPage
extension AMPPage {
    
    /// Fetch `NSDate` object from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `NSDate` object if the outlet was a datetime outlet and the page was already cached, else nil
    public func date(name: String) -> NSDate? {
        if let content = self.outlet(name) {
            if case let content as AMPDateTimeContent = content {
                return content.date
            }
        }
        return nil
    }
    
    /// Fetch `NSDate` object from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the date object becomes available, will not be called if the outlet
    ///                       is not a datetime outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func date(name: String, callback: (NSDate -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPDateTimeContent = content {
                if let d = content.date {
                    callback(d)
                }
            }
        }
        return self
    }
}
