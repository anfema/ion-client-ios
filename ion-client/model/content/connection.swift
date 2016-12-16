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


/// Connection content, carries a link to another collection, page or outlet
open class IONConnectionContent: IONContent {

    /// Value of the connection link
    open var link: String

    /// URL to the connected collection, page or outlet
    open var url: URL? {
        return URL(string: "\(ION.config.connectionScheme):\(self.link)")
    }


    /// Initialize connection content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized connection content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let connectionString = dict["connection_string"],
            case .jsonString(let value) = connectionString else {
                throw IONError.InvalidJSON(json)
        }

        self.link = value

        try super.init(json: json)
    }
}


/// Connection extensions to IONPage
extension IONPage {

    /// Fetch selected connection for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `NSURL` if the outlet is a connection outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func link(_ name: String, position: Int = 0) -> Result<URL, IONError> {
        let result = self.outlet(name, position: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? .unknownError)
        }

        guard case let connectionContent as IONConnectionContent = content else {
            return .failure(.outletIncompatible)
        }

        guard let url = connectionContent.url else {
            return .failure(.outletEmpty)
        }

        return .success(url)
    }


    /// Fetch selected connection for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the connection outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func link(_ name: String, position: Int = 0, callback: @escaping ((Result<URL, IONError>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.link(name, position: position))
        }

        return self
    }
}
