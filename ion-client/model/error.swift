//
//  error.swift
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

/// Error codes used by ION
public enum IONError: Error {
    /// No data received error (underlying error in associated value)
    case noData(Error?)

    /// Invalid json error, probably a transmission error
    case invalidJSON(JSONObject?)

    /// Expected a JSON object but found another thing
    case jsonObjectExpected(JSONObject?)

    /// Expected a JSON array but found another thing
    case jsonArrayExpected(JSONObject?)

    /// Expected top level JSON object or array but found something other
    case jsonArrayOrObjectExpected(JSONObject?)

    /// Unknown content type returned (IONContent subclass not found)
    case unknownContentType(String)

    /// Collection with that name is not available
    case collectionNotFound(String)

    /// Page with that name is not available
    case pageNotFound(collection: String, page: String)

    /// Page `child` is not a sub page of `parent`
    case invalidPageHierarchy(parent: String, child: String)

    /// Outlet with that name not found
    case outletNotFound(String)

    /// Outlet of incompatible type
    case outletIncompatible

    /// Empty outlet
    case outletEmpty

    /// Authorization with token or username/password tuple failed
    case notAuthorized

    /// ION Server unreachable, either the server is offline or the user is
    case serverUnreachable

    /// TODO: this is just a temp error for now
    case unknownError

    /// TODO: this is just a temp error for now
    case didFail

    /// Error domain for conversion into NSError
    public var errorDomain: String {
        return "com.anfema.ion"
    }
}
