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


/// DateTime content
open class IONDateTimeContent: IONContent {

    /// Parsed date
    open var date: Date?


    /// Initialize datetime content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized datetime content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawDateTime = dict["datetime"] else {
            throw IONError.invalidJSON(json)
        }

        if case .jsonString(let datetime) = rawDateTime {
            self.date = .makeFrom(isoDateString: datetime)
        }

        try super.init(json: json)
    }
}


/// Date extension to IONPage
extension IONPage {

    /// Fetch `NSDate` object for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `NSDate` if the outlet is a datetime outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func date(_ name: String, atPosition position: Int = 0) -> Result<Date, Error> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let timeContent as IONDateTimeContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let date = timeContent.date else {
            return .failure(IONError.outletEmpty)
        }

        return .success(date)
    }


    /// Fetch `NSDate` object for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the datetime outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSDate` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func date(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Date, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.date(name, atPosition: position))
        }

        return self
    }
}


public extension Content {

    /// Provides a dateTime content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func dateTimeContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONDateTimeContent? {
        return self.content(identifier, at: position)
    }


    func dateTimeContents(_ identifier: OutletIdentifier) -> [IONDateTimeContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONDateTimeContent] ?? nil)
    }


    func date(_ identifier: OutletIdentifier, at position: Position = 0) -> Date? {
        return dateTimeContent(identifier, at: position)?.date
    }
}
