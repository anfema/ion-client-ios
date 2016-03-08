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
import Alamofire

/// Number content, has a float value
public class IONNumberContent: IONContent {
    /// value
    public var value:Double = 0.0
    
    /// Initialize number content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized number content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawValue = dict["value"],
            case .JSONNumber(let value) = rawValue else {
                throw IONError.InvalidJSON(json)
        }
        
        self.value = value
    }
}

/// Number extension to IONPage
extension IONPage {
    
    /// Return value for named number outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: value if the outlet was a number outlet and the page was already cached, else nil
    public func number(name: String, position: Int = 0) -> Result<Double, IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        
        if case let content as IONNumberContent = content {
            return .Success(content.value)
        }
        return .Failure(.OutletIncompatible)
    }
    
    /// Return value for named number outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the number becomes available, will not be called if the outlet
    ///                       is not a number outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func number(name: String, position: Int = 0, callback: (Result<Double, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }
            if case let content as IONNumberContent = content {
                responseQueueCallback(callback, parameter: .Success(content.value))
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
}