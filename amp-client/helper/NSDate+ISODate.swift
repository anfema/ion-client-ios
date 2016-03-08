//
//  NSDate+ISODate.swift
//  ion-client
//
//  Created by Johannes Schriewer on 11/12/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
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
        return self.dateFormatter2.stringFromDate(date)
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


struct RFC822DateFormatter {
    static let sharedInstance = RFC822DateFormatter()
    let dateFormatter: NSDateFormatter
    
    init() {
        self.dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat  = "EEE', 'dd' 'MMM' 'yyyy' 'HH':'mm':'ss' GMT'"
        dateFormatter.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
        dateFormatter.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
    }
    
    func parse(string: String) -> NSDate? {
        return self.dateFormatter.dateFromString(string)
    }
    
    func format(date: NSDate) -> String {
        return self.dateFormatter.stringFromDate(date)
    }
}

public extension NSDate {
    public convenience init?(rfc822DateString: String) {
        guard let date = RFC822DateFormatter.sharedInstance.parse(rfc822DateString) else {
            return nil
        }
        self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate)
    }
    
    public var rfc822DateString: String {
        return RFC822DateFormatter.sharedInstance.format(self)
    }
}
