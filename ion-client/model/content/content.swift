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


/// Implement this protocol to gain `url` functionality
public protocol URLProvider {
    /// url to the file
    var url: URL? { get }
}


/// Implement this protocol to gain `temporaryURL` functionality
public protocol TemporaryURLProvider {
    /// Fetch temporary `NSURL` asynchronously
    ///
    /// - parameter callback: Block to call when the temporary url becomes available.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    ///
    func temporaryURL(_ callback: @escaping ((Result<URL>) -> Void))
}


/// IONContent base class, carries common values
open class IONContent {

    /// Variation name
    open var variation: String

    /// Outlet name
    open var outlet: String

    /// If the outlet is searchable or not
	open var isSearchable = false

    /// Array position
    open var position: Int = 0


    /// Initialize content object from JSON
    /// This is the content base class, it should never be instantiated by itself, only through it's subclasses!
    ///
    /// - parameter json: `JSONObject` that contains the serialized content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
	public init(json: JSONObject) throws {
		guard case .jsonDictionary(let dict) = json else {
			throw IONError.jsonObjectExpected(json)
		}

		guard let rawVariation = dict["variation"],
            let rawOutlet      = dict["outlet"],
            case .jsonString(let variation) = rawVariation,
            case .jsonString(let outlet)    = rawOutlet else {
                throw IONError.invalidJSON(json)
		}

		self.variation = variation
		self.outlet = outlet

        if let searchableObj = dict["is_searchable"] {
            if case .jsonBoolean(let searchable) = searchableObj {
                self.isSearchable = searchable
            }
        }

        if let p = dict["position"], case .jsonNumber(let pos) = p {
            self.position = Int(pos)
        }
	}
    
    
    init(outletIdentifier : ION.OutletIdentifier) {
        self.outlet = outletIdentifier
        self.variation = "default"
    }


    /// Initialize a content object from JSON
    ///
    /// This essentially removes the top JSON object casing and determines which object
    /// to instantiate from the name of the key of that JSON object
    ///
    /// - parameter json: The JSON object to parse
    /// - returns: Subclass of `IONContent` depending on the type provided in the JSON.
    /// - throws: `IONError.jsonObjectExpected`: The provided `JSONObject` is no `JSONDictionary`.
    ///           `IONError.InvalidJSON`: Missing keys in the provided `JSONDictionary` or wrong
    ///                                      value types.
    ///           `IONError.UnknownContentType`: The provied `JSONObject` can not be initialized
    ///                                             with any of the registered content types.
    open class func factory(json: JSONObject) throws -> IONContent {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawType = dict["type"],
            case .jsonString(let contentType) = rawType else {
                throw IONError.invalidJSON(json)
        }

        // dispatcher
        if contentType == "containercontent" {
            return try IONContainerContent(json: json)
        } else {
            for (type, lambda) in ION.config.registeredContentTypes {
                if contentType == type {
                    return try lambda(json)
                }
            }

            throw IONError.unknownContentType(contentType)
        }
    }
}
