//
//  ISODate.swift
//  IONClient
//
//  Created by Matthias Redlin on 18.02.22.
//  Copyright © 2022 anfema. All rights reserved.
//

import Foundation

extension DateFormatter
{
    fileprivate static let isoDateFormatter1: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }()
    
    fileprivate static let isoDateFormatter2: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }()
    
    fileprivate static let rfc822DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE', 'dd' 'MMM' 'yyyy' 'HH':'mm':'ss' GMT'"
        formatter.timeZone = .init(secondsFromGMT: 0)
        formatter.locale = .init(identifier: "en_US_POSIX")
        return formatter
    }()
}

extension Date
{
    func toISODateString() -> String
    {
        return DateFormatter.isoDateFormatter2.string(from: self)
    }
    
    func toRFC822DateString() -> String
    {
        return DateFormatter.rfc822DateFormatter.string(from: self)
    }
}

extension Date
{
    static func makeFrom(isoDateString: String) -> Date?
    {
        let date = DateFormatter.isoDateFormatter1.date(from: isoDateString)
        ?? DateFormatter.isoDateFormatter2.date(from: isoDateString)
        
        return date
            .map { .init(timeIntervalSinceReferenceDate: $0.timeIntervalSinceReferenceDate) }
    }

    static func makeFrom(rfc822DateString: String) -> Date?
    {
        return DateFormatter.rfc822DateFormatter.date(from:rfc822DateString)
            .map { .init(timeIntervalSinceReferenceDate: $0.timeIntervalSinceReferenceDate) }
    }
}
