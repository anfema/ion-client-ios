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
    var imageURL: URL? { get }

    /// url of the original image
    var originalImageURL: URL? { get }

    /// variation of this outlet (used for determining scale factor)
    var variation: String { get }
}

/// Queue used to calculate preview images
let serialQueue = DispatchQueue(label: "com.anfema.ion.SerialImageConverterQueue", attributes: [])

/// This protocol extension implements image loading, in principle you'll have to implement only `imageURL` to make it work
extension CanLoadImage {

    /// default implementation for checksum method (returns "null" if url not cached)
    public var checksumMethod: String {
        guard let thumbnail = self.imageURL,
            let _ = IONRequest.cachedData(forURL: thumbnail.absoluteString) else {
                return "null"
        }

        return "sha256"
    }

    /// default implementation for checksum (returns "invalid" if url not cached)
    public var checksum: String {
        guard let thumbnail = self.imageURL,
            let data = IONRequest.cachedData(forURL: thumbnail.absoluteString) else {
                return "invalid"
        }

        return (data as NSData).cryptoHash(.SHA256).hexString()
    }

    /// default implementation for checksum method (returns "null" if url not cached)
    public var originalChecksumMethod: String {
        guard let image = self.originalImageURL,
            let _ = IONRequest.cachedData(forURL: image.absoluteString) else {
                return "null"
        }

        return "sha256"
    }

    /// default implementation for checksum (returns "invalid" if url not cached)
    public var originalChecksum: String {
        guard let image = self.originalImageURL,
            let data = IONRequest.cachedData(forURL: image.absoluteString) else {
                return "invalid"
        }

        return (data as NSData).cryptoHash(.SHA256).hexString()
    }

    /// get a `CGDataProvider` for the image
    ///
    /// - parameter callback: Block to call when the data provider becomes available.
    ///                       Provides `Result.Success` containing an `CGDataProviderRef` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func dataProvider(_ callback: @escaping ((Result<CGDataProvider>) -> Void)) {
        guard let url = self.imageURL else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        IONRequest.fetchBinary(fromURL: url.absoluteString, queryParameters: nil, cacheBehaviour: ION.config.cacheBehaviour(.prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
                guard case .success(let filename) = result else {
                    responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                    return
                }

                guard let dataProvider = CGDataProvider(filename: filename) else {
                    if ION.config.loggingEnabled {
                        print("ION: Could not create dataprovider from file \(filename)")
                    }

                    return
                }

                responseQueueCallback(callback, parameter: .success(dataProvider))
        }
    }

    /// get a `CGDataProvider` for the original image
    ///
    /// - parameter callback: Block to call when the data provider becomes available.
    ///                       Provides `Result.Success` containing an `CGDataProviderRef` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func originalDataProvider(_ callback: @escaping ((Result<CGDataProvider>) -> Void)) {
        guard let url = self.originalImageURL else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        IONRequest.fetchBinary(fromURL: url.absoluteString, queryParameters: nil, cacheBehaviour: ION.config.cacheBehaviour(.prefer),
            checksumMethod: self.originalChecksumMethod, checksum: self.originalChecksum) { result in
                guard case .success(let filename) = result else {
                    responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                    return
                }

                guard let dataProvider = CGDataProvider(filename: filename) else {
                    if ION.config.loggingEnabled {
                        print("ION: Could not create dataprovider from file \(filename)")
                    }

                    return
                }

                responseQueueCallback(callback, parameter: .success(dataProvider))
        }
    }


    /// create a `CGImage` from the image data
    ///
    /// - parameter original: Whether to use the original or the processed data provider.
    /// - parameter callback: Block to call when the image has been allocated.
    ///                       Provides `Result.Success` containing an `CGImageRef` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func cgImage(usingOriginalDataProvider original: Bool = false, callback: @escaping ((Result<CGImage>) -> Void)) {
        let dataProviderFunc = ((original == true) ? self.originalDataProvider : self.dataProvider)
        dataProviderFunc() { result in
            guard case .success(let provider) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            let options = Dictionary<String, AnyObject>()
            guard let src = CGImageSourceCreateWithDataProvider(provider, options as CFDictionary?),
                let img = CGImageSourceCreateImageAtIndex(src, 0, options as CFDictionary?) else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            responseQueueCallback(callback, parameter: .success(img))
        }
    }

    /// create a `CGImage` from the original image data
    ///
    /// - parameter callback: block to execute when the image has been allocated
    public func originalCGImage(_ callback: @escaping ((Result<CGImage>) -> Void)) {
        self.cgImage(usingOriginalDataProvider: true, callback: callback)
    }


    /// create a `CGImage` with a specific size
    ///
    /// - parameter size: The target size of the thumbnail image while maintaining the aspect ratio of the source image.
    /// - parameter original: Whether to use the original or the processed data provider.
    /// - parameter callback: Block to call when the thumbnail image has been created.
    ///                       Provides `Result.Success` containing an `CGImageRef` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func thumbnail(withSize size: CGSize, usingOriginalDataProvider original: Bool = false, callback: @escaping ((Result<CGImage>) -> Void)) {
        let dataProviderFunc = ((original == true) ? self.originalDataProvider : self.dataProvider)

        dataProviderFunc() { result in
            guard case .success(let provider) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            serialQueue.async {
                let options: [NSString: Any] = [
                    kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height),
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceShouldCache: false,
                    kCGImageSourceShouldCacheImmediately: true,
                    kCGImageSourceCreateThumbnailWithTransform: true
                ]

                guard let src = CGImageSourceCreateWithDataProvider(provider, options as CFDictionary?) else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
                }

                guard let img = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary?) else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
                }

                responseQueueCallback(callback, parameter: .success(img))
            }
        }
    }


    #if os(iOS)
    /// create `UIImage` from the image data
    ///
    /// - parameter original: Whether to use the original or the processed data provider.
    /// - parameter callback: Block to call when the image has been allocated.
    ///                       Provides `Result.Success` containing an `UIImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func image(usingOriginalDataProvider original: Bool = false, callback: @escaping ((Result<UIImage>) -> Void)) {
        self.cgImage(usingOriginalDataProvider: original) { result in
            guard case .success(let img) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            // use the scale factor of the variation or 1.0 if none was found
            let scale = ION.config.variationScaleFactors[self.variation] ?? 1.0

            let uiImage = UIImage(cgImage: img, scale: scale, orientation: .up)
            responseQueueCallback(callback, parameter: .success(uiImage))
        }
    }

    /// create `UIImage` from the original image data
    ///
    /// - parameter callback: Block to call when the image has been allocated.
    ///                       Provides `Result.Success` containing an `UIImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func originalImage(_ callback: @escaping ((Result<UIImage>) -> Void)) {
        self.image(usingOriginalDataProvider: true, callback: callback)
    }
    #endif

    #if os(OSX)
    /// create `NSImage` from the image data
    ///
    /// - parameter original: Whether to use the original or the processed data provider.
    /// - parameter callback: Block to call when the image has been allocated.
    ///                       Provides `Result.Success` containing an `NSImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func image(usingOriginalDataProvider original: Bool = false, callback: @escaping ((Result<NSImage>) -> Void)) {
        self.cgImage(usingOriginalDataProvider: original) { result in
            guard case .success(let img) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            let nsImage = NSImage(cgImage: img, size: CGSize(width: CGFloat(img.width), height: CGFloat(img.height)))
            responseQueueCallback(callback, parameter: .success(nsImage))
        }
    }

    /// create `NSImage` from the original image data
    ///
    /// - parameter callback: Block to call when the image has been allocated.
    ///                       Provides `Result.Success` containing an `NSImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func originalImage(callback: @escaping ((Result<NSImage>) -> Void)) {
        self.image(usingOriginalDataProvider: true, callback: callback)
    }
    #endif
}
