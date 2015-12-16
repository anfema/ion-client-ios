//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

/// AMPContent base class, carries common values
public class AMPContent {
    
    /// variation name
    public var variation:String!
    
    /// outlet name
    public var outlet:String!
    
    /// searchable?
	public var isSearchable = false
   
    /// locale of this content
    public var localeCode:String!
    
    /// Initialize content content object from JSON
    ///
    /// This is the conten base class, it should never be instanciated by itself, only through it's subclasses!
    ///
    /// - parameter json: `JSONObject` that contains serialized content content object
	public init(json:JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.JSONObjectExpected(json)
		}
		
		guard (dict["variation"] != nil) && (dict["outlet"] != nil) && (dict["locale"] != nil),
              case .JSONString(let variation) = dict["variation"]!,
              case .JSONString(let outlet)    = dict["outlet"]!,
              case .JSONString(let locale)    = dict["locale"]! else {
			throw AMPError.InvalidJSON(json)
		}
		
		self.variation = variation
		self.outlet = outlet
        self.localeCode = locale
        
        if let searchableObj = dict["is_searchable"] {
            if case .JSONBoolean(let searchable) = searchableObj {
                self.isSearchable = searchable
            }
        }
	}
    
    /// Initialize a content object from JSON
    ///
    /// This essentially removes the top JSON object casing and determines which object
    /// to instanciate from the name of the key of that JSON object
    ///
    /// - parameter json: the JSON object to parse
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON, AMPError.Code.UnknownContentType
    public class func factory(json:JSONObject) throws -> AMPContent {
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["type"] != nil),
            case let contentTypeObj = dict["type"]!,
            case .JSONString(let contentType) = contentTypeObj else {
                throw AMPError.JSONObjectExpected(json)
        }
        
        // dispatcher
        if contentType == "containercontent" {
            return try AMPContainerContent(json: json)
        } else {
            for item in AMP.config.registeredContentTypes {
                if contentType == item.0 {
                    return try item.1(json)
                }
            }
            throw AMPError.UnknownContentType(contentType)
        }
    }
}
