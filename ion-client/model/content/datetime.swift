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
    
    /// Parsed date
    public var date: NSDate? = nil
    
    
    /// Initialize datetime content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized datetime content object
    override init(json: JSONObject) throws {
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
    
    /// Fetch `NSDate` object for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: Result.Success containing an `NSDate` if the outlet is a datetime outlet
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
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
    
    
    /// Fetch `NSDate` object for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the datetime outlet becomes available.
    ///                       Provides Result.Success containing an `NSDate` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    public func date(name: String, position: Int = 0, callback: (Result<NSDate, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.date(name, position: position))
        }
        
        return self
    }
}
