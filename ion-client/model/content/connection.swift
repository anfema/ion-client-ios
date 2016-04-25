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
    
    /// value of the connection link
    public var link: String
    
    /// url convenience
    public var url: NSURL? {
        return NSURL(string: "ion:\(self.link)")
    }

    
    /// Initialize connection content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized option content object
    override init(json:JSONObject) throws {
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
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: string if the outlet was an option outlet and the page was already cached, else nil
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
    
    /// Fetch selected connection for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the connection becomes available, will not be called if the outlet
    ///                       is not a option outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func link(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.link(name, position: position))
        }
        
        return self
    }
}