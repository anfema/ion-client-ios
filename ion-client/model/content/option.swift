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
    
    /// value for the selected option
    public var value:String
    
    /// Initialize option content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized option content object
    override init(json:JSONObject) throws {
        
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
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: string if the outlet was an option outlet and the page was already cached, else nil
    public func selectedOption(name: String, position: Int = 0) -> Result<String, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        if case let content as IONOptionContent = content {
            return .Success(content.value)
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch selected option for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the option becomes available, will not be called if the outlet
    ///                       is not a option outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func selectedOption(name: String, position: Int = 0, callback: (Result<String, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONOptionContent = content {
                responseQueueCallback(callback, parameter: .Success(content.value))
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
}