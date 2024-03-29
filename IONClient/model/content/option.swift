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
    public func selectedOption(_ name: String, atPosition position: Int = 0) -> Result<String, Error> {
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
    @discardableResult public func selectedOption(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<String, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.selectedOption(name, atPosition: position))
        }

        return self
    }
}


public extension Content {

    /// Provides a option content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func optionContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONOptionContent? {
        return self.content(identifier, at: position)
    }


    func optionContents(_ identifier: OutletIdentifier) -> [IONOptionContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONOptionContent] ?? nil)
    }


    func option(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {
        return optionContent(identifier, at: position)?.value
    }
}
