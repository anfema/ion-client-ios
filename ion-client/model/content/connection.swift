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
                throw IONError.invalidJSON(json)
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
    public func link(_ name: String, atPosition position: Int = 0) -> Result<URL> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let connectionContent as IONConnectionContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let url = connectionContent.url else {
            return .failure(IONError.outletEmpty)
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
    @discardableResult public func link(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<URL>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.link(name, atPosition: position))
        }

        return self
    }
}


public extension IONConnectionContent {

    public var components: [String] {
        return self.link.components(separatedBy: "/").filter({$0.isEmpty == false})
    }

    public var collectionIdentifier: String? {
        return components.first
    }

    public var pageIdentifier: String? {
        return components.last
    }
}


public extension Content {

    /// Provides a connection content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    public func connectionContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONConnectionContent? {
        return self.content(identifier, at: position)
    }

    public func connectionContents(_ identifier: OutletIdentifier) -> [IONConnectionContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONConnectionContent] ?? nil)
    }


    public func connection(_ identifier: OutletIdentifier, at position: Position = 0) -> (collectionIdentifier: CollectionIdentifier, pageIdentifier: PageIdentifier)? {
        guard let connectionContent = connectionContent(identifier),
            let collectionIdentifier = connectionContent.collectionIdentifier,
            let pageIdentifier = connectionContent.pageIdentifier else {
                return nil
        }

        return (collectionIdentifier: collectionIdentifier, pageIdentifier: pageIdentifier)
    }


    public func connectionPage(_ identifier: OutletIdentifier, at position: Position = 0, option: PageLoadingOption = .meta) -> AsyncResult<Page> {
        let asyncResult = AsyncResult<Page>()

        guard let connection = connection(identifier, at: position) else {
            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .failure(IONError.didFail))
            })
            return asyncResult
        }

        ION.page(pageIdentifier: connection.pageIdentifier, in: connection.collectionIdentifier, option: option).onSuccess { (page) in
            asyncResult.execute(result: .success(page))
            }.onFailure { (error) in
                asyncResult.execute(result: .failure(error))
        }

        return asyncResult
    }
}
