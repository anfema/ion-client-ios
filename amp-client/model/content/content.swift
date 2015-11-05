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

    // TODO: Array index?
    
    /// Initialize content content object from JSON
    ///
    /// This is the conten base class, it should never be instanciated by itself, only through it's subclasses!
    ///
    /// - Parameter json: `JSONObject` that contains serialized content content object
	init(json:JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard (dict["variation"] != nil) && (dict["outlet"] != nil),
              case .JSONString(let variation) = dict["variation"]!,
              case .JSONString(let outlet)    = dict["outlet"]! else {
			throw AMPError.Code.InvalidJSON(json)
		}
		
		self.variation = variation
		self.outlet = outlet
        
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
    /// - Parameter json: the JSON object to parse
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON, AMPError.Code.UnknownContentType
    public class func factory(json:JSONObject) throws -> AMPContent {
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["type"] != nil),
            case let contentTypeObj = dict["type"]!,
            case .JSONString(let contentType) = contentTypeObj else {
                throw AMPError.Code.JSONObjectExpected(json)
        }
        
        switch(contentType) {
        case "colorcontent":
            return try AMPColorContent(json: json)
        case "containercontent":
            return try AMPContainerContent(json: json)
        case "datetimecontent":
            return try AMPDateTimeContent(json: json)
        case "filecontent":
            return try AMPFileContent(json: json)
        case "flagcontent":
            return try AMPFlagContent(json: json)
        case "imagecontent":
            return try AMPImageContent(json: json)
        case "kvcontent":
            return try AMPKeyValueContent(json: json)
        case "numbercontent":
            return try AMPNumberContent(json: json)
        case "mediacontent":
            return try AMPMediaContent(json: json)
        case "optioncontent":
            return try AMPOptionContent(json: json)
        case "textcontent":
            return try AMPTextContent(json: json)
        default:
            throw AMPError.Code.UnknownContentType(contentType)
        }
    }
}
