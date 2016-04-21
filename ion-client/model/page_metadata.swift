//
//  page_metadata.swift
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

/// Page metadata, used if only small sionles of a page have to be used instead of downloading the whole thing
public class IONPageMeta: CanLoadImage {
    /// flag if the date formatter has already been instantiated
    static var formatterInstantiated = false
    
    /// page identifier
    public var identifier:String
    
    /// parent identifier, nil == top level
    public var parent:String?
    
    /// last change date
    public var lastChanged:NSDate
    
    /// page layout
    public var layout:String
    
    /// page position
    public var position: Int
    
    /// collection of this meta item
    public weak var collection: IONCollection?
    
    /// meta data attached to page
    private var metaData = [String:Array<String>]()
    
    /// children
    public var children:[IONPageMeta]? {
        guard let collection = self.collection else {
            return nil
        }
        if let list = collection.metadataList(self.identifier) {
            return list
        }
        return nil
    }
    
    /// Init metadata from JSON object
    ///
    /// - parameter json: serialized JSON object of page metadata
    /// - Throws: IONError.Code.JSONObjectExpected, IONError.Code.InvalidJSON
    internal init(json: JSONObject, position: Int, collection: IONCollection) throws {
        self.collection = collection
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawLastChanged = dict["last_changed"], rawParent = dict["parent"],
            rawIdentifier = dict["identifier"], rawLayout = dict["layout"],
            case .JSONString(let lastChanged) = rawLastChanged,
            case .JSONString(let layout) = rawLayout,
            case .JSONString(let identifier)  = rawIdentifier else {
                throw IONError.InvalidJSON(json)
        }
        
        if let date = NSDate(ISODateString: lastChanged) {
            self.lastChanged = date
        } else {
            self.lastChanged = NSDate.distantPast()
        }
        self.identifier  = identifier
        self.layout = layout
        self.position = position
        
        if let rawMeta = dict["meta"] {
            if case .JSONDictionary(let metaDict) = rawMeta {
                for (key, jsonObj) in metaDict {
                    if case .JSONString(let value) = jsonObj {
                        self.metaData[key] = [value]
                    }
                    // TODO: Test meta arrays, needs test data
                    if case .JSONArray(let array) = jsonObj {
                        var result = [String]()
                        for subitem in array {
                            if case .JSONString(let value) = subitem {
                                result.append(value)
                            }
                        }
                        self.metaData[key] = result
                    }
                }
            }
        }
        
        switch(rawParent) {
        case .JSONNull:
            self.parent = nil
        case .JSONString(let parent):
            self.parent = parent
        default:
            throw IONError.InvalidJSON(json)
        }
    }
    
    /// IONPageMeta can be subscripted by string to fetch metadata items
    ///
    /// - parameter index: key to return value for
    /// - returns: value or nil
    public subscript(index: String) -> String? {
        if let meta = self.metaData[index] {
            return meta[0]
        }
        return nil
    }

    /// IONPageMeta can be subscripted by string + position to fetch metadata items
    ///
    /// - parameter index: key to return value for
    /// - parameter position: array position to return
    /// - returns: value or nil
    public subscript(index: String, position: Int) -> String? {
        if let meta = self.metaData[index] {
            if meta.count > position {
                return meta[position]
            }
        }
        return nil
    }
    
    /// thumbnail image url for `CanLoadImage`
    public var imageURL:NSURL? {
        let taintedURL: String? = self["thumbnail"] ?? self["icon"]
 
        if let url = taintedURL
        {
            guard let escapedURL = url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) else
            {
                return nil
            }
            
            if let url = NSURL(string: escapedURL)
            {
                return url
            }
        }
        
        return nil
    }

    /// original image url for `CanLoadImage`, always nil
    public var originalImageURL:NSURL? {
        return nil
    }
    
    /// variation for `CanLoadImage`, returns `default` because the thumbnails are all the same for all variations
    public var variation: String {
        return "default"
    }
}
