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


/// Flag content, can be enabled or not
open class IONFlagContent: IONContent {

    /// Status of the flag
    open var isEnabled: Bool


    /// Initialize flag content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized flag content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawIsEnabled = dict["is_enabled"],
            case .jsonBoolean(let enabled) = rawIsEnabled else {
                throw IONError.invalidJSON(json)
        }

        self.isEnabled = enabled

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
    public func isSet(_ name: String, atPosition position: Int = 0) -> Result<Bool, Error> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let flagContent as IONFlagContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        return .success(flagContent.isEnabled)
    }


    /// Check if flag is set for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the flag outlet becomes available.
    ///                       Provides `Result.Success` containing an `Bool` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func isSet(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Bool, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.isSet(name, atPosition: position))
        }

        return self
    }
}


public extension Content {

    /// Provides a flag content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func flagContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONFlagContent? {
        return self.content(identifier, at: position)
    }


    func flagContents(_ identifier: OutletIdentifier) -> [IONFlagContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONFlagContent] ?? nil)
    }


    func flag(_ identifier: OutletIdentifier, at position: Position = 0) -> Bool {
        guard let content = flagContent(identifier, at: position) else {
                return false
        }

        return content.isEnabled
    }
}
