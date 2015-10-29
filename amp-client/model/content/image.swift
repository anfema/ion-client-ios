//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

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
    public var url:NSURL!
    
    /// original image mime type
    public var originalMimeType:String!
    
    /// original image dimensions
    public var originalSize:CGSize		= CGSizeZero
    
    /// original image file size
    public var originalFileSize:Int	    = 0
    
    /// original image URL
    public var originalURL:NSURL!
    
    /// image translation before cropping to final size
    public var translation:CGPoint		= CGPointZero
    
    /// image scale factor before cropping
    public var scale:Float				= 1.0
    
    /// checksumming method used
    public var checksumMethod:String!   = "null:"
    
    /// checksum of the file
    public var checksum:String!         = ""

    /// original file checksumming method
    public var originalChecksumMethod:String = "null:"
    
    /// original file checksum
    public var originalChecksum:String       = ""

    /// Initialize image content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized image content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["original_mime_type"] != nil) && (dict["image"] != nil) &&
            (dict["original_image"] != nil) && (dict["width"] != nil) && (dict["height"] != nil) &&
            (dict["original_width"] != nil) && (dict["original_height"] != nil) && (dict["file_size"] != nil) &&
            (dict["original_file_size"] != nil) && (dict["scale"] != nil) && (dict["translation_x"] != nil) &&
            (dict["translation_y"] != nil) && (dict["checksum"] != nil) && (dict["original_checksum"] != nil),
            case .JSONString(let mimeType)  = dict["mime_type"]!,
            case .JSONString(let oMimeType) = dict["original_mime_type"]!,
            case .JSONString(let fileUrl)   = dict["image"]!,
            case .JSONString(let oFileUrl)  = dict["original_image"]!,
            case .JSONString(let checksum)  = dict["checksum"]!,
            case .JSONString(let oChecksum) = dict["original_checksum"]!,
            case .JSONNumber(let width)     = dict["width"]!,
            case .JSONNumber(let height)    = dict["height"]!,
            case .JSONNumber(let oWidth)    = dict["original_width"]!,
            case .JSONNumber(let oHeight)   = dict["original_height"]!,
            case .JSONNumber(let fileSize)  = dict["file_size"]!,
            case .JSONNumber(let oFileSize) = dict["original_file_size"]!,
            case .JSONNumber(let scale)     = dict["scale"]!,
            case .JSONNumber(let transX)    = dict["translation_x"]!,
            case .JSONNumber(let transY)    = dict["translation_y"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        self.url      = NSURL(string: fileUrl)
        
        self.translation = CGPointMake(CGFloat(transX), CGFloat(transY))
        self.scale       = Float(scale)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)
        self.originalURL      = NSURL(string: oFileUrl)
        
        let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
        self.originalChecksumMethod = originalChecksumParts[0]
        self.originalChecksum = originalChecksumParts[1]

        let checksumParts = checksum.componentsSeparatedByString(":")
        self.checksumMethod = checksumParts[0]
        self.checksum = checksumParts[1]

    }
    
    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        return self.url
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
    public func image(name: String, callback: (UIImage -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPImageContent = content {
                content.image(callback)
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
    public func image(name: String, callback: (NSImage -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPImageContent = content {
                content.image(callback)
            }
        }
        return self
    }
    #endif
}
