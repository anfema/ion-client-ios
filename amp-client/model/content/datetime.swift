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
    public var date:NSDate? = nil
    
    /// Initialize datetime content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized datetime content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard let rawDateTime = dict["datetime"] else {
            throw AMPError.InvalidJSON(json)
        }
        
        if case .JSONString(let datetime) = rawDateTime {
            self.date = NSDate(isoDateString: datetime)
        }
    }
}

/// Date extension to AMPPage
extension AMPPage {
    
    /// Fetch `NSDate` object from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `NSDate` object if the outlet was a datetime outlet and the page was already cached, else nil
    public func date(name: String, position: Int = 0) -> NSDate? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPDateTimeContent = content {
                return content.date
            }
        }
        return nil
    }
    
    /// Fetch `NSDate` object from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the date object becomes available, will not be called if the outlet
    ///                       is not a datetime outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func date(name: String, position: Int = 0, callback: (NSDate -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPDateTimeContent = content {
                if let d = content.date {
                    callback(d)
                }
            }
        }
        return self
    }
}
