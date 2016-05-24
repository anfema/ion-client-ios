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


/// Number content, has a float value
public class IONNumberContent: IONContent {

    /// Value
    public var value: Double = 0.0


    /// Initialize number content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized number content object
    ///
    /// - throws: `IONError.JSONObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }

        guard let rawValue = dict["value"],
            case .JSONNumber(let value) = rawValue else {
                throw IONError.InvalidJSON(json)
        }

        self.value = value

        try super.init(json: json)
    }
}


/// Number extension to IONPage
extension IONPage {

    /// Return value for named number outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `Double` if the outlet is a number outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func number(name: String, position: Int = 0) -> Result<Double, IONError> {
        let result = self.outlet(name, position: position)

        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }

        guard case let numberContent as IONNumberContent = content else {
            return .Failure(.OutletIncompatible)
        }

        return .Success(numberContent.value)
    }


    /// Return value for named number outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the number outlet becomes available.
    ///                       Provides `Result.Success` containing an `Double` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func number(name: String, position: Int = 0, callback: (Result<Double, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.number(name, position: position))
        }

        return self
    }
}
