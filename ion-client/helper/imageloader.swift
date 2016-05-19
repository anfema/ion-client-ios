//
//  imageloader.swift
//  ion-client
//
//  Created by Johannes Schriewer on 29.10.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import HashExtensions

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif
import ImageIO

/// Implement this protocol to gain `dataProvider`, `cgImage` and `image` functionality for a image URL
public protocol CanLoadImage {
    /// checksumming method used
    var checksumMethod: String { get }
    
    /// checksumming method used for original file
    var originalChecksumMethod: String { get }
    
    /// checksum for the image
    var checksum: String { get }
    
    /// checksum for original file
    var originalChecksum: String { get }
    
    /// url of the image
    var imageURL: NSURL? { get }
    
    /// url of the original image
    var originalImageURL: NSURL? { get }
    
    /// variation of this outlet (used for determining scale factor)
    var variation: String { get }
}

/// Queue used to calculate preview images
let serialQueue = dispatch_queue_create("com.anfema.ion.SerialImageConverterQueue", DISPATCH_QUEUE_SERIAL)

/// This protocol extension implements image loading, in principle you'll have to implement only `imageURL` to make it work
extension CanLoadImage {
    
    /// default implementation for checksum method (returns "null" if url not cached)
    public var checksumMethod: String {
        guard let thumbnail = self.imageURL,
            let _ = IONRequest.cachedFile(thumbnail.URLString) else {
                return "null"
        }
        
        return "sha256"
    }
    
    /// default implementation for checksum (returns "invalid" if url not cached)
    public var checksum: String {
        guard let thumbnail = self.imageURL,
            let data = IONRequest.cachedFile(thumbnail.URLString) else {
                return "invalid"
        }
        
        return data.cryptoHash(.SHA256).hexString()
    }

    /// default implementation for checksum method (returns "null" if url not cached)
    public var originalChecksumMethod: String {
        guard let image = self.originalImageURL,
            let _ = IONRequest.cachedFile(image.URLString) else {
                return "null"
        }
        
        return "sha256"
    }
    
    /// default implementation for checksum (returns "invalid" if url not cached)
    public var originalChecksum: String {
        guard let image = self.originalImageURL,
            let data = IONRequest.cachedFile(image.URLString) else {
                return "invalid"
        }
        
        return data.cryptoHash(.SHA256).hexString()
    }

    /// get a `CGDataProvider` for the image
    ///
    /// - parameter callback: block to run when the provider becomes available
    public func dataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void)) {
        guard let url = self.imageURL else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
                guard case .Success(let filename) = result else {
                    responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                    return
                }
                
                guard let dataProvider = CGDataProviderCreateWithFilename(filename) else {
                    if ION.config.loggingEnabled {
                        print("ION: Could not create dataprovider from file \(filename)")
                    }
                    
                    return
                }
                
                responseQueueCallback(callback, parameter: .Success(dataProvider))
        }
    }

    /// get a `CGDataProvider` for the original image
    ///
    /// - parameter callback: block to run when the provider becomes available
    public func originalDataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void)) {
        guard let url = self.originalImageURL else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod: self.originalChecksumMethod, checksum: self.originalChecksum) { result in
                guard case .Success(let filename) = result else {
                    responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                    return
                }
                
                guard let dataProvider = CGDataProviderCreateWithFilename(filename) else {
                    if ION.config.loggingEnabled {
                        print("ION: Could not create dataprovider from file \(filename)")
                    }
                    
                    return
                }
                
                responseQueueCallback(callback, parameter: .Success(dataProvider))
        }
    }

    
    /// create a `CGImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func cgImage(original original: Bool = false, callback: (Result<CGImageRef, IONError> -> Void)) {
        let dataProviderFunc = ((original == true) ? self.originalDataProvider : self.dataProvider)
        dataProviderFunc() { result in
            guard case .Success(let provider) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            let options = Dictionary<String, AnyObject>()
            guard let src = CGImageSourceCreateWithDataProvider(provider, options),
                let img = CGImageSourceCreateImageAtIndex(src, 0, options) else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            responseQueueCallback(callback, parameter: .Success(img))
        }
    }

    /// create a `CGImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalCGImage(callback: (Result<CGImageRef, IONError> -> Void)) {
        self.cgImage(original: true, callback: callback)
    }
    
    
    /// create a `CGImage` with a specific size
    ///
    /// - parameter size: The target size of the thumbnail image while maintaining the aspect ratio of the source image.
    /// - parameter original: Whether to use the original or the processed data provider.
    /// - parameter callback: Block to execute when the thumbnail image has been created.
    public func thumbnail(size size: CGSize, original: Bool = false, callback: (Result<CGImageRef, IONError> -> Void)) {
        let dataProviderFunc = ((original == true) ? self.originalDataProvider : self.dataProvider)
        
        dataProviderFunc() { result in
            guard case .Success(let provider) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            dispatch_async(serialQueue) {
                let options: [NSString: NSObject] = [
                    kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCache: false,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ]

                guard let src = CGImageSourceCreateWithDataProvider(provider, options) else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
                }

                guard let img = CGImageSourceCreateThumbnailAtIndex(src, 0, options) else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
                }
                
                responseQueueCallback(callback, parameter: .Success(img))
            }
        }
    }

    
    #if os(iOS)
    /// create `UIImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func image(original original: Bool = false, callback: (Result<UIImage, IONError> -> Void)) {
        self.cgImage(original: original) { result in
            guard case .Success(let img) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            // use the scale factor of the variation or 1.0 if none was found
            let scale = ION.config.variationScaleFactors[self.variation] ?? 1.0
            
            let uiImage = UIImage(CGImage: img, scale: scale, orientation: .Up)
            responseQueueCallback(callback, parameter: .Success(uiImage))
        }
    }

    /// create `UIImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalImage(callback: (Result<UIImage, IONError> -> Void)) {
        self.image(original: true, callback: callback)
    }
    #endif
    
    #if os(OSX)
    /// create `NSImage` from the image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func image(original original: Bool = false, callback: (Result<NSImage, IONError> -> Void)) {
        self.cgImage(original: original) { result in
            guard case .Success(let img) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
    
            let nsImage = NSImage(CGImage: img, size: CGSizeMake(CGFloat(CGImageGetWidth(img)), CGFloat(CGImageGetHeight(img))))
            responseQueueCallback(callback, parameter: .Success(nsImage))
        }
    }

    /// create `NSImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalImage(callback: (Result<NSImage, IONError> -> Void)) {
        self.image(original: true, callback: callback)
    }
    #endif
}
