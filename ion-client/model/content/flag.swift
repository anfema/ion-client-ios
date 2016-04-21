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

/// Flag content, can be enabled or not
public class IONFlagContent: IONContent {
    /// status of the flag
    public var enabled:Bool
    
    /// Initialize flag content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized flag content object
    override init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawIsEnabled = dict["is_enabled"],
            case .JSONBoolean(let enabled) = rawIsEnabled else {
                throw IONError.InvalidJSON(json)
        }
        
        self.enabled = enabled

        try super.init(json: json)
    }
}

/// Flag extension to IONPage
extension IONPage {

    /// Check if flag is set for named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: true or false if the outlet was a flag outlet and the page was already cached, else nil
    public func isSet(name: String, position: Int = 0) -> Result<Bool, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        
        if case let content as IONFlagContent = content {
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
    public func isSet(name: String, position: Int = 0, callback: (Result<Bool, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }
            if case let content as IONFlagContent = content {
                responseQueueCallback(callback, parameter: .Success(content.enabled))
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
}