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


/// Option content, just carries the selected value not the options
public class IONOptionContent: IONContent {
    
    /// Value for the selected option
    public var value: String
    
    
    /// Initialize option content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized option content object
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawValue = dict["value"],
            case .JSONString(let value) = rawValue else {
                throw IONError.InvalidJSON(json)
        }
        
        self.value = value

        try super.init(json: json)
    }
}


/// Option extensions to IONPage
extension IONPage {
    
    /// Fetch selected option for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing a `String` if the outlet is an option outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func selectedOption(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        guard case let outletContent as IONOptionContent = content else {
            return .Failure(.OutletIncompatible)
        }
        
        return .Success(outletContent.value)
    }
    
    
    /// Fetch selected option for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the option outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func selectedOption(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.selectedOption(name, position: position))
        }
        
        return self
    }
}