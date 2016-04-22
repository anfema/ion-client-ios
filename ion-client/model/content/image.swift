//
//  content.swift
//  ion-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
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
public class IONImageContent: IONContent, CanLoadImage {
    
    /// mime type of the image
    public var mimeType:String
    
    /// dimensions of the image
    public var size:CGSize				= CGSizeZero
    
    /// file size in bytes
    public var fileSize:Int			    = 0
    
    /// URL of the image
    public var url:NSURL?
    
    /// original image mime type
    public var originalMimeType:String
    
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
    /// - parameter json: `JSONObject` that contains serialized image content object
    override init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType = dict["mime_type"], rawOriginalMimeType = dict["original_mime_type"], rawImage = dict["image"],
            rawOriginalImage = dict["original_image"], rawWidth = dict["width"], rawHeight = dict["height"],
            rawOriginalWidth = dict["original_width"], rawOriginalHeight = dict["original_height"], rawFileSize = dict["file_size"],
            rawOriginalFileSize = dict["original_file_size"], rawScale = dict["scale"], rawTranslationX = dict["translation_x"],
            rawTranslationY = dict["translation_y"], rawChecksum = dict["checksum"], rawOriginalChecksum = dict["original_checksum"],
            case .JSONString(let mimeType)  = rawMimeType,
            case .JSONString(let oMimeType) = rawOriginalMimeType,
            case .JSONNumber(let width)     = rawWidth,
            case .JSONNumber(let height)    = rawHeight,
            case .JSONNumber(let oWidth)    = rawOriginalWidth,
            case .JSONNumber(let oHeight)   = rawOriginalHeight,
            case .JSONNumber(let fileSize)  = rawFileSize,
            case .JSONNumber(let oFileSize) = rawOriginalFileSize,
            case .JSONNumber(let scale)     = rawScale,
            case .JSONNumber(let transX)    = rawTranslationX,
            case .JSONNumber(let transY)    = rawTranslationY else {
                throw IONError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
        self.fileSize = Int(fileSize)
        
        if case .JSONString(let fileUrl) = rawImage {
            self.url = NSURL(string: fileUrl)
            self.isValid = true
        }
        
        self.translation = CGPointMake(CGFloat(transX), CGFloat(transY))
        self.scale       = Float(scale)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .JSONString(let oFileUrl)  = rawOriginalImage {
            self.originalURL  = NSURL(string: oFileUrl)
        }
        
        if case .JSONString(let checksum)  = rawChecksum {
            let checksumParts = checksum.componentsSeparatedByString(":")
            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }
        
        if case .JSONString(let oChecksum) = rawOriginalChecksum {
            let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }
        
        try super.init(json: json)
    }
    
    /// Get a temporary valid url for this image file
    ///
    /// - parameter callback: block to call with the temporary URL, will not be called if there was an error while
    ///                       fetching the URL from the server
    public func temporaryURL(callback: (NSURL -> Void)) {
        guard let myURL = self.url else {
            return
        }
        IONRequest.postJSON("tokenize", queryParameters: nil, body: ["url" : myURL.absoluteString ]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json,
                let rawURL = dict["url"],
                case .JSONString(let urlString) = rawURL else {
                    return
            }
            
            guard let url = NSURL(string: urlString) else {
                return
            }
            
            responseQueueCallback(callback, parameter: url)
        }
    }

    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        return self.url
    }
    
    /// original image url for `CanLoadImage`
    public var originalImageURL:NSURL? {
        return self.originalURL
    }
}

/// Image extension to IONPage
extension IONPage {
    #if os(iOS)
    /// Allocate `UIImage` for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func image(name: String, position: Int = 0, callback: (Result<UIImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else
            {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONImageContent = content {
                content.image(callback: callback)
            }
        }
        return self
    }
    
    /// Allocate `UIImage` for named outlet (original unmodified image) async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func originalImage(name: String, position: Int = 0, callback: (Result<UIImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else
            {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONImageContent = content {
                content.originalImage(callback)
            }
        }
        return self
    }
    #endif

    #if os(OSX)
    /// Allocate `NSImage` for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func image(name: String, position: Int = 0, callback: (Result<NSImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else
            {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
    
            if case let content as IONImageContent = content {
                content.image(callback: callback)
            }
        }
        return self
    }
    
    /// Allocate `NSImage` for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter callback: block to call when the image becomes available, will not be called if the outlet
    ///                       is not a image outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func originalImage(name: String, position: Int = 0, callback: (Result<NSImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else
            {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
    
            if case let content as IONImageContent = content {
                content.originalImage(callback)
            }
        }
        return self
    }
    #endif
}
