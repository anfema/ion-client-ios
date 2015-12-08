//
//  page_metadata.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Alamofire
import DEjson

/// Page metadata, used if only small samples of a page have to be used instead of downloading the whole thing
public class AMPPageMeta: CanLoadImage {
    /// static date formatter to save allocation times
    static let formatter:NSDateFormatter = NSDateFormatter()
    static let formatter2:NSDateFormatter = NSDateFormatter()
    
    /// flag if the date formatter has already been instanciated
    static var formatterInstanciated = false
    
    /// page identifier
    public var identifier:String!
    
    /// parent identifier, nil == top level
    public var parent:String?
    
    /// last change date
    public var lastChanged:NSDate!
    
    /// page title if available
    public var title:String?
    
    /// page layout
    public var layout:String!
    
    /// thumbnail URL if available, if you want the UIImage use convenience functions below
    public var thumbnail:String?
    
    /// page position
    public var position: Int!
    
    /// collection of this meta item
    public weak var collection: AMPCollection?
    
    /// children
    public var children:[AMPPageMeta]? {
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
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON
    internal init(json: JSONObject, position: Int, collection: AMPCollection) throws {
        self.collection = collection
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["last_changed"] != nil) && (dict["parent"] != nil) &&
            (dict["identifier"] != nil) && (dict["layout"] != nil),
            case .JSONString(let lastChanged) = dict["last_changed"]!,
            case .JSONString(let layout) = dict["layout"]!,
            case .JSONString(let identifier)  = dict["identifier"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        
        if !AMPPageMeta.formatterInstanciated {
            AMPPageMeta.formatter.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"
            AMPPageMeta.formatter.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
            AMPPageMeta.formatter.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
            
            AMPPageMeta.formatter2.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            AMPPageMeta.formatter2.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
            AMPPageMeta.formatter2.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
            AMPPageMeta.formatterInstanciated = true
        }
        
        // avoid crashing if microseconds are not there
        var lc = AMPPageMeta.formatter.dateFromString(lastChanged)
        if lc == nil {
            lc = AMPPageMeta.formatter2.dateFromString(lastChanged)
        }
        self.lastChanged = lc
        self.identifier  = identifier
        self.layout = layout
        self.position = position
        
        if (dict["title"]  != nil) {
            if case .JSONString(let title) = dict["title"]! {
                self.title = title
            }
        }
        
        if (dict["thumbnail"]  != nil) {
            if case .JSONString(let thumbnail) = dict["thumbnail"]! {
                self.thumbnail = thumbnail
            }
        }
        
        switch(dict["parent"]!) {
        case .JSONNull:
            self.parent = nil
        case .JSONString(let parent):
            self.parent = parent
        default:
            throw AMPError.InvalidJSON(json)
        }
    }
    
    /// thumbnail image url for `CanLoadImage`
    public var imageURL:NSURL? {
        if let thumbnail = self.thumbnail {
            return NSURL(string: thumbnail)!
        }
        return nil
    }

    /// original image url for `CanLoadImage`, always nil
    public var originalImageURL:NSURL? {
        return nil
    }
    
    /// variation for `CanLoadImage`, returns `default` because the thumbnails are all the same for all variations
    public var variation: String! {
        return "default"
    }
}
