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
    
    // original file name
    public var filename:String!
    
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
    /// - parameter json: `JSONObject` that contains serialized media content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard let rawName = dict["name"], rawMimeType = dict["mime_type"], rawOriginalMimeType = dict["original_mime_type"], rawFile = dict["file"],
            rawOriginalFile = dict["original_file"], rawWidth = dict["width"], rawHeight = dict["height"],
            rawOriginalWidth = dict["original_width"], rawOriginalHeight = dict["original_height"], rawFileSize = dict["file_size"],
            rawOriginalFileSize = dict["original_file_size"], rawChecksum = dict["checksum"], rawOriginalChecksum = dict["original_checksum"],
            rawLength = dict["length"], rawOriginalLength = dict["original_length"],
            case .JSONString(let name)      = rawName,
            case .JSONString(let mimeType)  = rawMimeType,
            case .JSONString(let oMimeType) = rawOriginalMimeType,
            case .JSONNumber(let width)     = rawWidth,
            case .JSONNumber(let height)    = rawHeight,
            case .JSONNumber(let oWidth)    = rawOriginalWidth,
            case .JSONNumber(let oHeight)   = rawOriginalHeight,
            case .JSONNumber(let fileSize)  = rawFileSize,
            case .JSONNumber(let oFileSize) = rawOriginalFileSize,
            case .JSONNumber(let length)    = rawLength,
            case .JSONNumber(let oLength)   = rawOriginalLength else {
                throw AMPError.InvalidJSON(json)
        }
        
        self.filename = name
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        if case .JSONString(let fileUrl) = rawFile {
            self.url     = NSURL(string: fileUrl)
            self.isValid = true
        }
        
        if case .JSONString(let checksum)  = rawChecksum {
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
        if case .JSONString(let oFileUrl) = rawOriginalFile {
            self.originalURL      = NSURL(string: oFileUrl)
        }
        
        if case .JSONString(let oChecksum) = rawOriginalChecksum {
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
    /// - parameter callback: block to call when file data gets available, will not be called if there was an error
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
                if AMP.config.loggingEnabled {
                    print("AMP: Could not read file \(filename)")
                }
            }
        }
    }
    
    /// Get a temporary valid url for this media file
    ///
    /// - parameter callback: block to call with the temporary URL, will not be called if there was an error while
    ///                       fetching the URL from the server
    public func temporaryURL(callback: (NSURL -> Void)) {
        AMPRequest.postJSON("tokenize", queryParameters: nil, body: [ "url" : self.url.absoluteString ]) { result in
            guard result.isSuccess,
                let json = result.value,
                case .JSONDictionary(let dict) = json where dict["url"] != nil,
                case .JSONString(let url) = dict["url"]! else {
                    return
            }

            dispatch_async(AMP.config.responseQueue) {
                callback(NSURL(string: url)!)
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
    
    /// original image url for `CanLoadImage`
    public var originalImageURL:NSURL? {
        if self.originalMimeType.hasPrefix("image/") {
            return self.originalURL
        }
        return nil
    }
}

/// Media content extensions to AMPPage
extension AMPPage {
    
    /// Fetch URL from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `NSURL` object if the outlet was a media outlet and the page was already cached, else nil
    public func mediaURL(name: String, position: Int = 0) -> NSURL? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPMediaContent = content {
                return content.url
            }
        }
        if let content = self.outlet(name, position: position) {
            if case let content as AMPFileContent = content {
                return content.url
            }
        }
        return nil
    }
    
    /// Fetch URL from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaURL(name: String, position: Int = 0, callback: (NSURL -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPMediaContent = content {
                if let url = content.url {
                    callback(url)
                }
            }
            if case let content as AMPFileContent = content {
                if let url = content.url {
                    callback(url)
                }
            }
        }
        return self
    }
    
    /// Fetch temporary valid URL from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func temporaryURL(name: String, position: Int = 0, callback: (NSURL -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPMediaContent = content {
                content.temporaryURL { url in
                    callback(url)
                }
            }
            if case let content as AMPFileContent = content {
                content.temporaryURL { url in
                    callback(url)
                }
            }
            if case let content as AMPImageContent = content {
                content.temporaryURL { url in
                    callback(url)
                }
            }
        }
        return self
    }
    
   
    /// Fetch data for media file async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaData(name: String, position: Int = 0, callback: (NSData -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPMediaContent = content {
                content.data(callback)
            }
        }
        return self
    }
}