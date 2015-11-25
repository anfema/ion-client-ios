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
#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif
import DEjson

/// Image content, has OS specific image loading functionality
public class AMPImageContent : AMPContent, CanLoadImage {
    
    /// mime type of the image
    public var mimeType:String!
    
    /// dimensions of the image
    public var size:CGSize				= CGSizeZero
    
    /// file size in bytes
    public var fileSize:Int			    = 0
    
    /// URL of the image
    public var url:NSURL?
    
    /// original image mime type
    public var originalMimeType:String!
    
    /// original image dimensions
    public var originalSize:CGSize		= CGSizeZero
    
    /// original image file size
    public var originalFileSize:Int	    = 0
    
    /// original image URL
    public var originalURL:NSURL?
    
    /// image translation before cropping to final size
    public var translation:CGPoint		= CGPointZero
    
    /// image scale factor before cropping
    public var scale:Float				= 1.0
    
    /// checksumming method used
    public var checksumMethod:String   = "null"
    
    /// checksum of the file
    public var checksum:String         = ""

    /// original file checksumming method
    public var originalChecksumMethod:String = "null"
    
    /// original file checksum
    public var originalChecksum:String       = ""
    
    /// is this a valid image
    public var isValid = false

    /// Initialize image content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized image content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["original_mime_type"] != nil) && (dict["image"] != nil) &&
            (dict["original_image"] != nil) && (dict["width"] != nil) && (dict["height"] != nil) &&
            (dict["original_width"] != nil) && (dict["original_height"] != nil) && (dict["file_size"] != nil) &&
            (dict["original_file_size"] != nil) && (dict["scale"] != nil) && (dict["translation_x"] != nil) &&
            (dict["translation_y"] != nil) && (dict["checksum"] != nil) && (dict["original_checksum"] != nil),
            case .JSONString(let mimeType)  = dict["mime_type"]!,
            case .JSONString(let oMimeType) = dict["original_mime_type"]!,
            case .JSONNumber(let width)     = dict["width"]!,
            case .JSONNumber(let height)    = dict["height"]!,
            case .JSONNumber(let oWidth)    = dict["original_width"]!,
            case .JSONNumber(let oHeight)   = dict["original_height"]!,
            case .JSONNumber(let fileSize)  = dict["file_size"]!,
            case .JSONNumber(let oFileSize) = dict["original_file_size"]!,
            case .JSONNumber(let scale)     = dict["scale"]!,
            case .JSONNumber(let transX)    = dict["translation_x"]!,
            case .JSONNumber(let transY)    = dict["translation_y"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        
        if case .JSONString(let fileUrl) = dict["image"]! {
            self.url = NSURL(string: fileUrl)
            self.isValid = true
        }
        
        self.translation = CGPointMake(CGFloat(transX), CGFloat(transY))
        self.scale       = Float(scale)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .JSONString(let oFileUrl)  = dict["original_image"]! {
            self.originalURL  = NSURL(string: oFileUrl)
        }
        
        if case .JSONString(let checksum)  = dict["checksum"]! {
            let checksumParts = checksum.componentsSeparatedByString(":")
            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }
        
        if case .JSONString(let oChecksum) = dict["original_checksum"]! {
            let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }
    }
    
    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        return self.url
    }
    
    public var originalImageURL:NSURL? {
        return self.originalURL
    }
}

/// Image extension to AMPPage
extension AMPPage {
    #if os(iOS)
    /// Allocate `UIImage` for named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func image(name: String, position: Int = 0, callback: (UIImage -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPImageContent = content {
                content.image(callback: callback)
            }
        }
        return self
    }
    
    /// Allocate `UIImage` for named outlet (original unmodified image) async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func originalImage(name: String, position: Int = 0, callback: (UIImage -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPImageContent = content {
                content.originalImage(callback)
            }
        }
        return self
    }
    #endif

    #if os(OSX)
    /// Allocate `NSImage` for named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func image(name: String, position: Int = 0, callback: (NSImage -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPImageContent = content {
                content.image(callback: callback)
            }
        }
        return self
    }
    
    /// Allocate `NSImage` for named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func originalImage(name: String, position: Int = 0, callback: (NSImage -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPImageContent = content {
                content.originalImage(callback)
            }
        }
        return self
    }
    #endif
}
