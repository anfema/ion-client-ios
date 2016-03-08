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
public enum IONError: ErrorType {
    /// No data received error (underlying error in associated value)
    case NoData(ErrorType?)
    
    /// Invalid json error, probably a transmission error
    case InvalidJSON(JSONObject?)
    
    /// Expected a JSON object but found another thing
    case JSONObjectExpected(JSONObject?)
    
    /// Expected a JSON array but found another thing
    case JSONArrayExpected(JSONObject?)
    
    /// Expected top level JSON object or array but found something other
    case JSONArrayOrObjectExpected(JSONObject?)
    
    /// Unknown content type returned (IONContent subclass not found)
    case UnknownContentType(String)
    
    /// Collection with that name is not available
    case CollectionNotFound(String)
    
    /// Page with that name is not available
    case PageNotFound(String)
    
    /// Page `child` is not a sub page of `parent`
    case InvalidPageHierarchy(parent: String, child: String)
    
    /// Outlet with that name not found
    case OutletNotFound(String)
    
    /// Outlet of incompatible type
    case OutletIncompatible

    /// Empty outlet
    case OutletEmpty

    /// Authorization with token or username/password tuple failed
    case NotAuthorized
    
    /// ION Server unreachable, either the server is offline or the user is
    case ServerUnreachable
    
    /// TODO: this is just a temp error for now
    case DidFail
    
    /// Error domain for conversion into NSError
    public var errorDomain: String {
        return "com.anfema.ion"
    }
}
