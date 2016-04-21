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

/// IONContent base class, carries common values
public class IONContent {
    
    /// variation name
    public var variation:String
    
    /// outlet name
    public var outlet:String
    
    /// searchable?
	public var isSearchable = false
    
    /// Array position
    public var position: Int
   
    /// Initialize content content object from JSON
    ///
    /// This is the content base class, it should never be instantiated by itself, only through it's subclasses!
    ///
    /// - parameter json: `JSONObject` that contains serialized content content object
	public init(json:JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			throw IONError.JSONObjectExpected(json)
		}
		
		guard let rawVariation = dict["variation"], rawOutlet = dict["outlet"],
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

        if let positionObj = dict["position"] {
            if case .JSONNumber(let pos) = positionObj {
                self.position = Int(pos)
            } else {
                self.position = 0
            }
        } else {
            self.position = 0
        }
	}
    
    /// Initialize a content object from JSON
    ///
    /// This essentially removes the top JSON object casing and determines which object
    /// to instantiate from the name of the key of that JSON object
    ///
    /// - parameter json: the JSON object to parse
    /// - Throws: IONError.Code.JSONObjectExpected, IONError.Code.InvalidJSON, IONError.Code.UnknownContentType
    public class func factory(json:JSONObject) throws -> IONContent {
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
