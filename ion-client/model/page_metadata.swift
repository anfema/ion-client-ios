//
//  page_metadata.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

/// Page metadata, used if only small parts of a page have to be used instead of downloading the whole thing
public class IONPageMeta: CanLoadImage {
    /// Flag if the date formatter has already been instantiated
    static var formatterInstantiated = false

    /// Page identifier
    public var identifier: String

    /// Parent identifier, nil == top level
    public var parent: String?

    /// Last change date
    public var lastChanged: NSDate

    /// Page layout
    public var layout: String

    /// Page position
    public var position: Int

    /// Collection of this meta item
    public weak var collection: IONCollection?

    /// Meta data attached to page
    private var metaData = [String: [String]]()

    /// Children
    public var children: [IONPageMeta]? {
        return self.collection?.metadataList(self.identifier).optional()
    }


    /// Init metadata from JSON object
    ///
    /// - parameter json: Serialized JSON object of page metadata
    /// - parameter position: Position in the array
    /// - parameter collection: The `IONCollection` the page belongs to
    ///
    /// - throws: IONError.JSONObjectExpected: The provided JSONObject is no JSONDictionary.
    ///           IONError.InvalidJSON: Missing keys in the provided JSONDictionary or wrong
    ///                                 value types.
    ///
    internal init(json: JSONObject, position: Int, collection: IONCollection) throws {
        self.collection = collection

        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }

        guard let rawLastChanged    = dict["last_changed"],
            let rawParent           = dict["parent"],
            let rawIdentifier       = dict["identifier"],
            let rawLayout           = dict["layout"],
            case .JSONString(let lastChanged) = rawLastChanged,
            case .JSONString(let layout)      = rawLayout,
            case .JSONString(let identifier)  = rawIdentifier else {
                throw IONError.InvalidJSON(json)
        }

        self.lastChanged = NSDate(ISODateString: lastChanged) ?? NSDate.distantPast()
        self.identifier  = identifier
        self.layout = layout
        self.position = position

        if let rawMeta = dict["meta"] {
            if case .JSONDictionary(let metaDict) = rawMeta {
                for (key, jsonObj) in metaDict {
                    if case .JSONString(let value) = jsonObj {
                        self.metaData[key] = [value]
                    }

                    // TODO: Test meta arrays, needs test data
                    // TODO: Are meta arrays still a thing? If so - we need to update the subscript functions so that they are position safe
                    if case .JSONArray(let array) = jsonObj {
                        var result = [String]()

                        for subitem in array {
                            if case .JSONString(let value) = subitem {
                                result.append(value)
                            }
                        }

                        self.metaData[key] = result
                    }
                }
            }
        }

        switch rawParent {
        case .JSONNull:
            self.parent = nil
        case .JSONString(let parent):
            self.parent = parent
        default:
            throw IONError.InvalidJSON(json)
        }
    }


    /// IONPageMeta can be subscripted by string to fetch metadata items
    ///
    /// - parameter index: Key to return value for
    /// - returns: Value or nil
    public subscript(index: String) -> String? {
        if let meta = self.metaData[index] {
            return meta.first
        }

        return nil
    }


    /// IONPageMeta can be subscripted by string + position to fetch metadata items
    ///
    /// - parameter index: Key to return value for
    /// - parameter position: Array position to return
    /// - returns: Value or nil
    public subscript(index: String, position: Int) -> String? {
        if let meta = self.metaData[index] {
            if meta.count > position {
                return meta[position]
            }
        }

        return nil
    }


    /// Retrieve IONPage from metadata
    ///
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides Result.Success containing an `IONPage` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    public func page(callback: (Result<IONPage, IONError> -> Void)) {
        guard let collection = collection else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        ION.collection(collection.identifier).page(identifier, callback: callback)
    }


    /// thumbnail image url for `CanLoadImage`
    public var imageURL: NSURL? {
        if let urlString = self["thumbnail"] ?? self["icon"] where urlString.isEmpty == false {
            return NSURL(string: urlString)
        }

        return nil
    }


    /// Original image url for `CanLoadImage`, always nil
    public var originalImageURL: NSURL? {
        return nil
    }


    /// Variation for `CanLoadImage`, returns `default` because the thumbnails are all the same for all variations
    public var variation: String {
        return "default"
    }
}
