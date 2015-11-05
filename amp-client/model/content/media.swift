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

/// Media content, may be image, audio or video content
public class AMPMediaContent : AMPContent, CanLoadImage {
    
    /// mime type of media file
    public var mimeType:String!
    
    /// dimensions of the media file if applicable
    public var size = CGSizeZero
    
    /// file size in bytes
    public var fileSize = 0

    /// checksumming method used
    public var checksumMethod:String = "null"

    /// checksum of the file
    public var checksum:String = ""
    
    /// length in seconds of the media file if applicable
    public var length = Float(0.0)
    
    /// url to the media file
    public var url:NSURL!
    
    /// original media file mime type
    public var originalMimeType:String!
    
    /// dimensions of the original media file if applicable
    public var originalSize = CGSizeZero

    /// original media file size in bytes
    public var originalFileSize = 0
    
    /// checksumming method used
    public var originalChecksumMethod:String = "null"
    
    /// checksum of the original file
    public var originalChecksum:String = ""
    
    /// length in seconds of the original media file if applicable
    public var originalLength = Float(0.0)

    /// url to the original file
    public var originalURL:NSURL!
    
    /// is this a valid media content object
    public var isValid = false
    
    /// Initialize media content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized media content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["original_mime_type"] != nil) && (dict["file"] != nil) &&
            (dict["original_file"] != nil) && (dict["width"] != nil) && (dict["height"] != nil) &&
            (dict["original_width"] != nil) && (dict["original_height"] != nil) && (dict["file_size"] != nil) &&
            (dict["original_file_size"] != nil) && (dict["checksum"] != nil) && (dict["original_checksum"] != nil) &&
            (dict["length"] != nil) && (dict["original_length"] != nil),
            case .JSONString(let mimeType)  = dict["mime_type"]!,
            case .JSONString(let oMimeType) = dict["original_mime_type"]!,
            case .JSONNumber(let width)     = dict["width"]!,
            case .JSONNumber(let height)    = dict["height"]!,
            case .JSONNumber(let oWidth)    = dict["original_width"]!,
            case .JSONNumber(let oHeight)   = dict["original_height"]!,
            case .JSONNumber(let fileSize)  = dict["file_size"]!,
            case .JSONNumber(let oFileSize) = dict["original_file_size"]!,
            case .JSONNumber(let length)    = dict["length"]!,
            case .JSONNumber(let oLength)   = dict["original_length"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        if case .JSONString(let fileUrl) = dict["file"]! {
            self.url     = NSURL(string: fileUrl)
            self.isValid = true
        }
        
        if case .JSONString(let checksum)  = dict["checksum"]! {
            let checksumParts = checksum.componentsSeparatedByString(":")
            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }
        self.length   = Float(length)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)
        if case .JSONString(let oFileUrl) = dict["original_file"]! {
            self.originalURL      = NSURL(string: oFileUrl)
        }
        
        if case .JSONString(let oChecksum) = dict["original_checksum"]! {
            let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }
        self.originalLength   = Float(oLength)
    }
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - Parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
    public func data(callback: (NSData -> Void)) {
        AMPRequest.fetchBinary(self.url.URLString, queryParameters: nil, cached: true,
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
                return
            }
            do {
                let data = try NSData(contentsOfFile: filename, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                dispatch_async(AMP.config.responseQueue) {
                    callback(data)
                }
            } catch {
                print("AMP: Could not read file \(filename)")
            }
        }
    }
    
    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }
        return nil
    }
}

/// Media content extensions to AMPPage
extension AMPPage {
    
    /// Fetch URL from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `NSURL` object if the outlet was a media outlet and the page was already cached, else nil
    // TODO: Write test for mediaURL functions
    public func mediaURL(name: String) -> NSURL? {
        if let content = self.outlet(name) {
            if case let content as AMPMediaContent = content {
                return content.url
            }
        }
        return nil
    }
    
    /// Fetch URL from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaURL(name: String, callback: (NSURL -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPMediaContent = content {
                if let url = content.url {
                    callback(url)
                }
            }
        }
        return self
    }
   
    /// Fetch data for media file async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaData(name: String, callback: (NSData -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPMediaContent = content {
                content.data(callback)
            }
        }
        return self
    }
}