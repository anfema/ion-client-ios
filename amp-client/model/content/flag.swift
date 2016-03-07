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
import Alamofire

/// Flag content, can be enabled or not
public class AMPFlagContent : AMPContent {
    /// status of the flag
    public var enabled:Bool!
    
    /// Initialize flag content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized flag content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard let rawIsEnabled = dict["is_enabled"],
            case .JSONBoolean(let enabled) = rawIsEnabled else {
                throw AMPError.InvalidJSON(json)
        }
        
        self.enabled = enabled
    }
}

/// Flag extension to AMPPage
extension AMPPage {

    /// Check if flag is set for named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: true or false if the outlet was a flag outlet and the page was already cached, else nil
    public func isSet(name: String, position: Int = 0) -> Result<Bool, AMPError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        
        if case let content as AMPFlagContent = content {
            return .Success(content.enabled)
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    /// Check if flag is set for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the flag becomes available, will not be called if the outlet
    ///                       is not a flag outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func isSet(name: String, position: Int = 0, callback: (Result<Bool, AMPError> -> Void)) -> AMPPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                callback(.Failure(result.error!))
                return
            }
            if case let content as AMPFlagContent = content {
                callback(.Success(content.enabled))
            } else {
                callback(.Failure(.OutletIncompatible))
            }
        }
        return self
    }
}