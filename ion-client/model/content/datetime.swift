//
//  content.swift
//  ion-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson
import iso_rfc822_date

/// DateTime content
public class IONDateTimeContent: IONContent {
    /// parsed date
    public var date:NSDate? = nil
    
    /// Initialize datetime content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized datetime content object
    override init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawDateTime = dict["datetime"] else {
            throw IONError.InvalidJSON(json)
        }
        
        if case .JSONString(let datetime) = rawDateTime {
            self.date = NSDate(ISODateString: datetime)
        }
        
        try super.init(json: json)
    }
}

/// Date extension to IONPage
extension IONPage {
    
    /// Fetch `NSDate` object from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `NSDate` object if the outlet was a datetime outlet and the page was already cached, else nil
    public func date(name: String, position: Int = 0) -> Result<NSDate, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }

        if case let content as IONDateTimeContent = content {
            if let date = content.date {
                return .Success(date)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch `NSDate` object from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the date object becomes available, will not be called if the outlet
    ///                       is not a datetime outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func date(name: String, position: Int = 0, callback: (Result<NSDate, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.date(name, position: position))
        }
        
        return self
    }
}
