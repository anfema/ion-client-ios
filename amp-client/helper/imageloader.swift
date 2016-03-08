//
//  imageloader.swift
//  amp-client
//
//  Created by Johannes Schriewer on 29.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import HashExtensions
import Alamofire

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif
import ImageIO

/// Implement this protocol to gain `dataProvider`, `cgImage` and `image` functionality for a image URL
public protocol CanLoadImage {
    /// checksumming method used
    var checksumMethod:String! { get }
    
    /// checksumming method used for original file
    var originalChecksumMethod:String! { get }
    
    /// checksum for the image
    var checksum:String! { get }
    
    /// checksum for original file
    var originalChecksum:String! { get }
    
    /// url of the image
    var imageURL:NSURL? { get }
    
    /// url of the original image
    var originalImageURL:NSURL? { get }
    
    /// variation of this outlet (used for determining scale factor)
    var variation:String! { get }
}

/// This protocol extension implements image loading, in principle you'll have to implement only `imageURL` to make it work
extension CanLoadImage {
    
    /// default implementation for checksum method (returns "null" if url not cached)
    public var checksumMethod:String! {
        guard let thumbnail = self.imageURL,
            let _ = AMPRequest.cachedFile(thumbnail.URLString) else {
                return "null"
        }
        return "sha256"
    }
    
    /// default implementation for checksum (returns "invalid" if url not cached)
    public var checksum:String! {
        guard let thumbnail = self.imageURL,
            let data = AMPRequest.cachedFile(thumbnail.URLString) else {
                return "invalid"
        }
        
        return data.cryptoHash(.SHA256).hexString()
    }

    /// default implementation for checksum method (returns "null" if url not cached)
    public var originalChecksumMethod:String! {
        guard let image = self.originalImageURL,
            let _ = AMPRequest.cachedFile(image.URLString) else {
                return "null"
        }
        return "sha256"
    }
    
    /// default implementation for checksum (returns "invalid" if url not cached)
    public var originalChecksum:String! {
        guard let image = self.originalImageURL,
            let data = AMPRequest.cachedFile(image.URLString) else {
                return "invalid"
        }
        
        return data.cryptoHash(.SHA256).hexString()
    }

    /// get a `CGDataProvider` for the image
    ///
    /// - parameter callback: block to run when the provider becomes available
    public func dataProvider(callback: (CGDataProviderRef -> Void)) {
        guard let url = self.imageURL else {
            return
        }
        AMPRequest.fetchBinary(url.URLString, queryParameters: nil, cached: AMP.config.cacheBehaviour(.Prefer),
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
                guard case .Success(let filename) = result else {
                    return
                }
                if let dataProvider = CGDataProviderCreateWithFilename(filename) {
                    dispatch_async(AMP.config.responseQueue) {
                        callback(dataProvider)
                    }
                } else {
                    if AMP.config.loggingEnabled {
                        print("AMP: Could not create dataprovider from file \(filename)")
                    }
                }
        }
    }

    /// get a `CGDataProvider` for the original image
    ///
    /// - parameter callback: block to run when the provider becomes available
    public func originalDataProvider(callback: (CGDataProviderRef -> Void)) {
        guard let url = self.originalImageURL else {
            return
        }
        AMPRequest.fetchBinary(url.URLString, queryParameters: nil, cached: AMP.config.cacheBehaviour(.Prefer),
            checksumMethod:self.originalChecksumMethod, checksum: self.originalChecksum) { result in
                guard case .Success(let filename) = result else {
                    return
                }
                if let dataProvider = CGDataProviderCreateWithFilename(filename) {
                    dispatch_async(AMP.config.responseQueue) {
                        callback(dataProvider)
                    }
                } else {
                    if AMP.config.loggingEnabled {
                        print("AMP: Could not create dataprovider from file \(filename)")
                    }
                }
        }
    }

    
    /// create a `CGImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func cgImage(original original: Bool = false, callback: (Result<CGImageRef, AMPError> -> Void)) {
        let dataProviderFunc = ((original == true) ? self.originalDataProvider : self.dataProvider)
        dataProviderFunc() { provider in
            let options = Dictionary<String, AnyObject>()
            if let src = CGImageSourceCreateWithDataProvider(provider, options) {
                if let img = CGImageSourceCreateImageAtIndex(src, 0, options) {
                    callback(.Success(img))
                }
            }
        }
        
        // Fixme: add .Failure callback call
    }

    /// create a `CGImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalCGImage(callback: (Result<CGImageRef, AMPError> -> Void)) {
        self.cgImage(original:true, callback: callback)
    }

    
    #if os(iOS)
    /// create `UIImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func image(original original: Bool = false, callback: (Result<UIImage, AMPError> -> Void)) {
        self.cgImage(original: original) { result in
            guard case .Success(let img) = result else
            {
                callback(.Failure(result.error!))
                return
            }
            
            let uiImage = UIImage(CGImage: img, scale: AMP.config.variationScaleFactors[self.variation]!, orientation: .Up)
            callback(.Success(uiImage))
        }
    }

    /// create `UIImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalImage(callback: (Result<UIImage, AMPError> -> Void)) {
        self.image(original: true, callback: callback)
    }
    #endif
    
    #if os(OSX)
    /// create `NSImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func image(original original: Bool = false, callback: (Result<NSImage, AMPError> -> Void)) {
        self.cgImage(original: original) { img in
            let nsImage = NSImage(CGImage: img, size:CGSizeMake(CGFloat(CGImageGetWidth(img)), CGFloat(CGImageGetHeight(img))))
            callback(nsImage)
        }
    }

    /// create `NSImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalImage(callback: (Result<NSImage, AMPError> -> Void)) {
        self.image(original: true, callback: callback)
    }
    #endif
}