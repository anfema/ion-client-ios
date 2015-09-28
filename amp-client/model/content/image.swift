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
import ImageIO

public class AMPImageContent : AMPContentBase {
    var mimeType:String!
    var size:CGSize				= CGSizeZero
    var fileSize:Int			= 0
    var url:NSURL!
    var originalMimeType:String!
    var originalSize:CGSize		= CGSizeZero
    var originalFileSize:Int	= 0
    var originalURL:NSURL!
    var translation:CGPoint		= CGPointZero
    var scale:Float				= 1.0
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["original_mime_type"] != nil) && (dict["image"] != nil) &&
            (dict["original_image"] != nil) && (dict["width"] != nil) && (dict["height"] != nil) &&
            (dict["original_width"] != nil) && (dict["original_height"] != nil) && (dict["file_size"] != nil) &&
            (dict["original_file_size"] != nil) && (dict["scale"] != nil) && (dict["translation_x"] != nil) &&
            (dict["translation_y"] != nil),
            case .JSONString(let mimeType)  = dict["mime_type"]!,
            case .JSONString(let oMimeType) = dict["original_mime_type"]!,
            case .JSONString(let fileUrl)   = dict["image"]!,
            case .JSONString(let oFileUrl)  = dict["original_image"]!,
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
    }
    
    public func dataProvider(callback: (CGDataProviderRef -> Void)) {
        // TODO: Cache invalidation
        AMPRequest.fetchBinary(self.url.URLString, queryParameters: nil) { result in
            guard case .Success(let filename) = result else {
                return
            }
            if let dataProvider = CGDataProviderCreateWithFilename(filename) {
                dispatch_async(AMP.config.responseQueue) {
                    callback(dataProvider)
                }
            } else {
                print("AMP: Could not create dataprovider from file \(filename)")
            }
        }
    }

    
    public func cgImage(callback: (CGImageRef -> Void)) {
        self.dataProvider() { provider in
            let options = Dictionary<String, AnyObject>()
            if let src = CGImageSourceCreateWithDataProvider(provider, options) {
                if let img = CGImageSourceCreateImageAtIndex(src, 0, options) {
                    callback(img)
                }
            }
        }
    }
    #if os(iOS)
    public func uiImage(callback: (UIImage -> Void)) {
        self.cgImage() { img in
            let uiImage = UIImage(CGImage: img)
            callback(uiImage)
        }
    }
    #endif
    
    #if os(OSX)
    public func nsImage(callback: (NSImage -> Void)) {
        self.cgImage() { img in
            let nsImage = NSImage(CGImage: img, size:CGSizeMake(CGFloat(CGImageGetWidth(img)), CGFloat(CGImageGetHeight(img))))
                callback(nsImage)
            }
        }
    #endif
}

extension AMPPage {
    #if os(iOS)
    public func image(name: String, callback: (UIImage -> Void)) {
        self.outlet(name) { content in
            if case .Image(let img) = content {
                img.uiImage(callback)
            }
        }
    }
    #endif

    #if os(OSX)
    public func image(name: String, callback: (NSImage -> Void)) {
        self.outlet(name) { content in
            if case .Image(let img) = content {
                img.nsImage(callback)
            }
        }
    }
    #endif
}
