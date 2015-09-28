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
    var mimeType:String!
    var size:CGSize				= CGSizeZero
    var fileSize:Int			= 0
    var checksumMethod:String!
    var checksum:String!
    var length:Float			= 0.0
    var url:NSURL!
    
    var originalMimeType:String!
    var originalSize:CGSize		= CGSizeZero
    var originalFileSize:Int	= 0
    var originalChecksumMethod:String!
    var originalChecksum:String!
    var originalLength:Float	= 0.0
    var originalURL:NSURL!
    
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
    public func mediaURL(name: String) -> NSURL? {
        if let content = self.outlet(name) {
            if case .Media(let media) = content {
                return media.url
            }
        }
        return nil
    }
    
    public func mediaURL(name: String, callback: (NSURL -> Void)) {
        self.outlet(name) { content in
            if case .Media(let media) = content {
                if let url = media.url {
                    callback(url)
                }
            }
        }
    }
   
    public func mediaData(name: String, callback: (NSData -> Void)) {
        self.outlet(name) { content in
            if case .Media(let media) = content {
                media.data(callback)
            }
        }
    }
}