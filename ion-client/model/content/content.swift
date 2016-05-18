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
    var url: NSURL? { get }
}


/// Implement this protocol to gain `temporaryURL` functionality
public protocol TemporaryURLProvider {
    func temporaryURL(callback: (Result<NSURL, IONError> -> Void))
}


/// IONContent base class, carries common values
public class IONContent {
    
    /// Variation name
    public var variation: String
    
    /// Outlet name
    public var outlet: String
    
    /// If the outlet is searchable or not
	public var isSearchable = false
    
    /// Array position
    public var position: Int
    
    
    /// Initialize content object from JSON
    ///
    /// This is the content base class, it should never be instantiated by itself, only through it's subclasses!
    ///
    /// - parameter json: `JSONObject` that contains the serialized content object
	public init(json: JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			throw IONError.JSONObjectExpected(json)
		}
		
		guard let rawVariation = dict["variation"],
            let rawOutlet      = dict["outlet"],
            case .JSONString(let variation) = rawVariation,
            case .JSONString(let outlet)    = rawOutlet else {
                throw IONError.InvalidJSON(json)
		}
		
		self.variation = variation
		self.outlet = outlet
        
        if let searchableObj = dict["is_searchable"] {
            if case .JSONBoolean(let searchable) = searchableObj {
                self.isSearchable = searchable
            }
        }
        
        if let p = dict["position"], case .JSONNumber(let pos) = p {
            self.position = Int(pos)
        } else {
            self.position = 0
        }
	}
    
    
    /// Initialize a content object from JSON
    ///
    /// This essentially removes the top JSON object casing and determines which object
    /// to instantiate from the name of the key of that JSON object
    ///
    /// - parameter json: The JSON object to parse
    /// - returns: Subclass of `IONContent` depending on the type provided in the JSON.
    /// - throws: `IONError.JSONObjectExpected`: The provided `JSONObject` is no `JSONDictionary`.
    ///           `IONError.InvalidJSON`: Missing keys in the provided `JSONDictionary` or wrong
    ///                                      value types.
    ///           `IONError.UnknownContentType`: The provied `JSONObject` can not be initialized
    ///                                             with any of the registered content types.
    public class func factory(json: JSONObject) throws -> IONContent {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawType = dict["type"],
            case .JSONString(let contentType) = rawType else {
                throw IONError.InvalidJSON(json)
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
            
            throw IONError.UnknownContentType(contentType)
        }
    }
}
