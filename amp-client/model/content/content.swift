//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson

public class AMPContentBase {
	public var variation:String!            /// variation name
	public var outlet:String!               /// outlet name
	public var isSearchable = false         /// searchable?

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
}

public enum AMPContent {
	case Color(AMPColorContent)
	case Container(AMPContainerContent)
	case DateTime(AMPDateTimeContent)
	case File(AMPFileContent)
	case Flag(AMPFlagContent)
	case Image(AMPImageContent)
	case KeyValue(AMPKeyValueContent)
	case Media(AMPMediaContent)
	case Option(AMPOptionContent)
	case Text(AMPTextContent)
	case Invalid
	   
    /// Get the `AMPContentBase` object from the specialized subclass
    ///
    /// - Returns: Essentially the associated object casted to `AMPContentBase`
    public func getBaseObject() -> AMPContentBase? {
        // This is ridiculous... come on swift!
        switch self {
        case .Color(let cObj):
            return cObj
        case .Container(let cObj):
            return cObj
        case .DateTime(let cObj):
            return cObj
        case .File(let cObj):
            return cObj
        case .Flag(let cObj):
            return cObj
        case .Image(let cObj):
            return cObj
        case .KeyValue(let cObj):
            return cObj
        case .Media(let cObj):
            return cObj
        case .Option(let cObj):
            return cObj
        case .Text(let cObj):
            return cObj
        case .Invalid:
            return nil
        }
    }
    
    /// Initialize a content object from JSON
    ///
    /// This essentially removes the top JSON object casing and determines which object
    /// to instanciate from the name of the key of that JSON object
    ///
    /// - Parameter json: the JSON object to parse
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON, AMPError.Code.UnknownContentType
    public init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            self = .Invalid
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["type"] != nil),
            case let contentTypeObj = dict["type"]!,
            case .JSONString(let contentType) = contentTypeObj else {
                self = .Invalid
                throw AMPError.Code.JSONObjectExpected(json)
        }
        
        switch(contentType) {
        case "colorcontent":
            try self = .Color(AMPColorContent(json: json))
        case "containercontent":
            try self = .Container(AMPContainerContent(json: json))
        case "datetimecontent":
            try self = .DateTime(AMPDateTimeContent(json: json))
        case "filecontent":
            try self = .File(AMPFileContent(json: json))
        case "flagcontent":
            try self = .Flag(AMPFlagContent(json: json))
        case "imagecontent":
            try self = .Image(AMPImageContent(json: json))
        case "kvcontent":
            try self = .KeyValue(AMPKeyValueContent(json: json))
        case "mediacontent":
            try self = .Media(AMPMediaContent(json: json))
        case "optioncontent":
            try self = .Option(AMPOptionContent(json: json))
        case "textcontent":
            try self = .Text(AMPTextContent(json: json))
        default:
            self = .Invalid
            throw AMPError.Code.UnknownContentType(contentType)
        }
    }
}

