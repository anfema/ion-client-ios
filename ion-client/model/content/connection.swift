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
public class IONConnectionContent: IONContent {
    
    /// Value of the connection link
    public var link: String
    
    /// URL to the connected collection, page or outlet
    public var url: NSURL? {
        return NSURL(string: "\(ION.config.connectionScheme):\(self.link)")
    }

    
    /// Initialize connection content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized connection content object
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let connectionString = dict["connection_string"],
            case .JSONString(let value) = connectionString else {
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
    /// - returns: Result.Success containing an `NSURL` if the outlet is a connection outlet
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
    public func link(name: String, position: Int = 0) -> Result<NSURL, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }

        if case let content as IONConnectionContent = content {
            if let url = content.url {
                return .Success(url)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    
    /// Fetch selected connection for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the connection outlet becomes available.
    ///                       Provides Result.Success containing an `NSURL` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    public func link(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.link(name, position: position))
        }
        
        return self
    }
}