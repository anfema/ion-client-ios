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
    
    /// Status of the flag
    public var enabled: Bool
    
    
    /// Initialize flag content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized flag content object
    override init(json: JSONObject) throws {
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
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `Bool` if the outlet is a flag outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func isSet(name: String, position: Int = 0) -> Result<Bool, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        guard case let flagContent as IONFlagContent = content else {
            return .Failure(.OutletIncompatible)
        }
        
        return .Success(flagContent.enabled)
    }
    
    
    /// Check if flag is set for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the flag outlet becomes available.
    ///                       Provides `Result.Success` containing an `Bool` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func isSet(name: String, position: Int = 0, callback: (Result<Bool, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.isSet(name, position: position))
        }
        
        return self
    }
}
