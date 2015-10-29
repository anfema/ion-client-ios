//
//  imageloader.swift
//  amp-client
//
//  Created by Johannes Schriewer on 29.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

public protocol CanLoadImage {
    var checksumMethod:String! { get }
    var checksum:String! { get }
    var imageURL:NSURL? { get }
}

extension CanLoadImage {
    /// get a `CGDataProvider` for the image
    ///
    /// - Parameter callback: block to run when the provider becomes available
    public func dataProvider(callback: (CGDataProviderRef -> Void)) {
        guard let url = self.imageURL else {
            return
        }
        AMPRequest.fetchBinary(url.URLString, queryParameters: nil, cached: true,
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
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
    
    /// create a `CGImage` from the image data
    ///
    /// - Parameter callback: block to execute when the image has been allocated
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
    /// create `UIImage` from the image data
    ///
    /// - Parameter callback: block to execute when the image has been allocated
    public func image(callback: (UIImage -> Void)) {
        self.cgImage() { img in
            let uiImage = UIImage(CGImage: img)
            callback(uiImage)
        }
    }
    #endif
    
    #if os(OSX)
    /// create `NSImage` from the image data
    ///
    /// - Parameter callback: block to execute when the image has been allocated
    public func image(callback: (NSImage -> Void)) {
        self.cgImage() { img in
            let nsImage = NSImage(CGImage: img, size:CGSizeMake(CGFloat(CGImageGetWidth(img)), CGFloat(CGImageGetHeight(img))))
            callback(nsImage)
        }
    }
    #endif
}