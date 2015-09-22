//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import UIKit
import DEjson


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
    
    func cgImage() -> CGImageRef? {
        // TODO: fetch data from cache
        return nil
    }
    
    func uiImage() -> UIImage? {
        // TODO: fetch data from cache
        return nil
    }
}

extension AMPPage {
    public func image(name: String) -> UIImage? {
        if let content = self.outlet(name) {
            if case .Image(let img) = content {
                return img.uiImage()
            }
        }
        return nil
    }
    
    public func image(name: String, callback: (UIImage -> Void)) {
        self.outlet(name) { content in
            if case .Image(let img) = content {
                if let image = img.uiImage() {
                    callback(image)
                }
            }
        }
    }
}