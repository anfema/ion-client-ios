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


/// Container content, contains other content objects
open class IONContainerContent: IONContent {

    /// Children of this container
    open var children: [IONContent]


    /// Initialize container content object from JSON
    /// Container content children can be accessed by subscripting the container content object
    ///
    /// - parameter json: `JSONObject` that contains the serialized container content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.jsonArrayExpected` when `json["children"]` is no `JSONArray`
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawChildren = dict["children"],
            case .jsonArray(let children) = rawChildren else {
                throw IONError.jsonArrayExpected(json)
        }

        self.children = []
        for child in children {
            do {
                try self.children.append(IONContent.factory(child))
            } catch {
                if ION.config.loggingEnabled {
                    print("ION: Deserialization failed")
                }
            }
        }

        try super.init(json: json)
    }


    /// Container content has a subscript for it's children
    subscript(index: Int) -> IONContent? {
        guard index > -1 && index < self.children.count else {
            return nil
        }

        return self.children[index]
    }
}


/// Container extension to IONPage
extension IONPage {

    /// Fetch `IONContent`-Array for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an array of `IONContent` objects if the outlet is a container outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func children(_ name: String, position: Int = 0) -> Result<[IONContent]> {
        let result = self.outlet(name, position: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        if case let content as IONContainerContent = content {
            return .success(content.children)
        }

        return .failure(IONError.outletIncompatible)
    }


    /// Fetch `IONContent`-Array for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the container outlet becomes available.
    ///                       Provides `Result.Success` containing an array of `IONContent` objects when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func children(_ name: String, position: Int = 0, callback: @escaping ((Result<[IONContent]>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.children(name, position: position))
        }

        return self
    }
}
