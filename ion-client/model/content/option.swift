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
open class IONOptionContent: IONContent {

    /// Value for the selected option
    open var value: String


    /// Initialize option content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized option content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawValue = dict["value"],
            case .jsonString(let value) = rawValue else {
                throw IONError.invalidJSON(json)
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
    public func selectedOption(_ name: String, atPosition position: Int = 0) -> Result<String> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let outletContent as IONOptionContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        return .success(outletContent.value)
    }


    /// Fetch selected option for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the option outlet becomes available.
    ///                       Provides `Result.Success` containing an `String` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func selectedOption(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<String>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.selectedOption(name, atPosition: position))
        }

        return self
    }
}


public extension Page {
    
    /// Provides a option content with the given identifier taking an optional position into account
    /// - parameter identifier: The identifier of the content
    /// - parameter position: The position within the content (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access an content
    public func optionContent(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> IONOptionContent? {
        return self.content(identifier, at: position)
    }
    
    
    public func option(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> String? {
        return optionContent(identifier, at: position)?.value
    }
}
