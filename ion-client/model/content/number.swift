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
open class IONNumberContent: IONContent {

    /// Value
    open var value: Double = 0.0


    /// Initialize number content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized number content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawValue = dict["value"],
            case .jsonNumber(let value) = rawValue else {
                throw IONError.invalidJSON(json)
        }

        if let rawDecimalPlaces = dict["decimal_places"],
            case .jsonNumber(let places) = rawDecimalPlaces {
            self.value = value / pow(10, places)
        } else {
            self.value = value
        }

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
    public func number(_ name: String, atPosition position: Int = 0) -> Result<Double> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let numberContent as IONNumberContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        return .success(numberContent.value)
    }


    /// Return value for named number outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the number outlet becomes available.
    ///                       Provides `Result.Success` containing an `Double` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func number(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Double>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.number(name, atPosition: position))
        }

        return self
    }
}


public extension Page {
    
    /// Provides a number content with the given identifier taking an optional position into account
    /// - parameter identifier: The identifier of the content
    /// - parameter position: The position within the content (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access an content
    public func numberContent(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> IONNumberContent? {
        return self.content(identifier, at: position)
    }
    
    
    public func number(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> Double? {
        return numberContent(identifier, at: position)?.value
    }
}
