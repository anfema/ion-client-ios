//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPDateTimeContent : AMPContentBase {
    public var date:NSDate?
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["datetime"] != nil),
            case .JSONString(let datetime) = dict["datetime"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        fmt.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
        fmt.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
        
        self.date = fmt.dateFromString(datetime)
    }
}

extension AMPPage {
    public func date(name: String) -> NSDate? {
        if let content = self.outlet(name) {
            if case .DateTime(let date) = content {
                return date.date
            }
        }
        return nil
    }
    
    public func date(name: String, callback: (NSDate -> Void)) {
        self.outlet(name) { content in
            if case .DateTime(let date) = content {
                if let d = date.date {
                    callback(d)
                }
            }
        }
    }
}
