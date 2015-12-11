//
//  NSDate+ISODate.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 11/12/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

struct ISODateFormatter {
    static let sharedInstance = ISODateFormatter()
    let dateFormatter1: NSDateFormatter
    let dateFormatter2: NSDateFormatter
    
    init() {
        self.dateFormatter1 = NSDateFormatter()
        dateFormatter1.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"
        dateFormatter1.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter1.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
 
        self.dateFormatter2 = NSDateFormatter()
        dateFormatter2.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        dateFormatter2.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter2.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
    }
    
    func parse(string: String) -> NSDate? {
        var lc = self.dateFormatter1.dateFromString(string)
        if lc == nil {
            lc = self.dateFormatter2.dateFromString(string)
        }
        return lc
    }
    
    func format(date: NSDate) -> String {
        return self.dateFormatter1.stringFromDate(date)
    }
}

public extension NSDate {
    public convenience init?(isoDateString: String) {
        guard let date = ISODateFormatter.sharedInstance.parse(isoDateString) else {
            return nil
        }
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
    }
    
    public var isoDateString: String {
        return ISODateFormatter.sharedInstance.format(self)
    }
}