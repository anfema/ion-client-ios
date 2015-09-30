//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPMediaContent : AMPContentBase {
    var mimeType:String!        /// mime type of media file
    var size = CGSizeZero       /// dimensions of the media file if applicable
    var fileSize = 0            /// file size in bytes
    var checksumMethod:String!  /// checksumming method used
    var checksum:String!        /// checksum of the file
    var length = Float(0.0)     /// length in seconds of the media file if applicable
    var url:NSURL!              /// url to the media file
    
    var originalMimeType:String!        /// original media file mime type
    var originalSize = CGSizeZero       /// dimensions of the original media file if applicable
    var originalFileSize = 0            /// original media file size in bytes
    var originalChecksumMethod:String!  /// checksumming method used
    var originalChecksum:String!        /// checksum of the original file
    var originalLength = Float(0.0)     /// length in seconds of the original media file if applicable
    var originalURL:NSURL!              /// url to the original file
    
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
            case .JSONString(let fileUrl)   = dict["file"]!,
            case .JSONString(let oFileUrl)  = dict["original_file"]!,
            case .JSONNumber(let width)     = dict["width"]!,
            case .JSONNumber(let height)    = dict["height"]!,
            case .JSONNumber(let oWidth)    = dict["original_width"]!,
            case .JSONNumber(let oHeight)   = dict["original_height"]!,
            case .JSONNumber(let fileSize)  = dict["file_size"]!,
            case .JSONNumber(let oFileSize) = dict["original_file_size"]!,
            case .JSONString(let checksum)  = dict["checksum"]!,
            case .JSONString(let oChecksum) = dict["original_checksum"]!,
            case .JSONNumber(let length)    = dict["length"]!,
            case .JSONNumber(let oLength)   = dict["original_length"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        self.url      = NSURL(string: fileUrl)
        let checksumParts = checksum.componentsSeparatedByString(":")
        self.checksumMethod = checksumParts[0]
        self.checksum = checksumParts[1]
        self.length   = Float(length)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)
        self.originalURL      = NSURL(string: oFileUrl)
        let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
        self.originalChecksumMethod = originalChecksumParts[0]
        self.originalChecksum = originalChecksumParts[1]
        self.originalLength   = Float(oLength)
    }
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - Parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
    public func data(callback: (NSData -> Void)) {
        // TODO: Cache invalidation
        AMPRequest.fetchBinary(self.url.URLString, queryParameters: nil) { result in
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
}

extension AMPPage {
    
    /// Fetch URL from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `NSURL` object if the outlet was a media outlet and the page was already cached, else nil
    public func mediaURL(name: String) -> NSURL? {
        if let content = self.outlet(name) {
            if case .Media(let media) = content {
                return media.url
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
            if case .Media(let media) = content {
                if let url = media.url {
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
            if case .Media(let media) = content {
                media.data(callback)
            }
        }
        return self
    }
}