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
public class IONContainerContent: IONContent {
    /// children to this container
    public var children:[IONContent]
    
    /// Initialize container content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized container content object
    ///
    /// Container content children can be accessed by subscripting the container content object
    override init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawChildren = dict["children"],
            case .JSONArray(let children) = rawChildren else {
                throw IONError.JSONArrayExpected(json) // TODO: return InvalidJSON so all IONContents behave the same way?
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
        guard index < self.children.count else {
            return nil
        }
        return self.children[index]
    }
}

/// Container extension to IONPage
extension IONPage {
    
    /// Fetch `IONContent`-Array from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: Array of `IONContent` objects if the outlet was a container outlet and the page was already
    ///            cached, else nil
    public func children(name: String, position: Int = 0) -> Result<[IONContent], IONError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        if case let content as IONContainerContent = content {
            return .Success(content.children)
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch `IONContent`-Array from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the children become available, will not be called if the outlet
    ///                       is not a container outlet or non-existant or fetching the outlet was canceled because
    ///                       of a communication error
    public func children(name: String, position: Int = 0, callback: (Result<[IONContent], IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONContainerContent = content {
                responseQueueCallback(callback, parameter: .Success(content.children))
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        
        return self
    }
}
