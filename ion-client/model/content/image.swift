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
public class IONImageContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {

    /// MIME type of the image
    public var mimeType: String

    /// Dimensions of the image
    public var size: CGSize = CGSize.zero

    /// File size in bytes
    public var fileSize: Int = 0

    /// URL of the image
    public var url: NSURL?

    /// Original image mime type
    public var originalMimeType: String

    /// Original image dimensions
    public var originalSize: CGSize = CGSize.zero

    /// Original image file size
    public var originalFileSize: Int = 0

    /// Original image URL
    public var originalURL: NSURL?

    /// Image translation before cropping to final size
    public var translation: CGPoint = CGPoint.zero

    /// Image scale factor before cropping
    public var scale: Float = 1.0

    /// Method used for checksum calculation
    public var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    public var checksum: String = ""

    /// Original method used for checksum calculation
    public var originalChecksumMethod: String = "null"

    /// Original checksum as hexadecimal encoded string
    public var originalChecksum: String = ""

    /// If the image file is valid or not
    public var isValid = false


    /// Initialize image content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized image content object
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }

        guard let rawMimeType           = dict["mime_type"],
            let rawOriginalMimeType     = dict["original_mime_type"],
            let rawImage                = dict["image"],
            let rawOriginalImage        = dict["original_image"],
            let rawWidth                = dict["width"],
            let rawHeight               = dict["height"],
            let rawOriginalWidth        = dict["original_width"],
            let rawOriginalHeight       = dict["original_height"],
            let rawFileSize             = dict["file_size"],
            let rawOriginalFileSize     = dict["original_file_size"],
            let rawScale                = dict["scale"],
            let rawTranslationX         = dict["translation_x"],
            let rawTranslationY         = dict["translation_y"],
            let rawChecksum             = dict["checksum"],
            let rawOriginalChecksum     = dict["original_checksum"],
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
        self.size     = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.fileSize = Int(fileSize)

        if case .JSONString(let fileUrl) = rawImage {
            self.url = NSURL(string: fileUrl)
            self.isValid = true
        }

        self.translation = CGPoint(x: CGFloat(transX), y: CGFloat(transY))
        self.scale       = Float(scale)

        self.originalMimeType = oMimeType
        self.originalSize     = CGSize(width: CGFloat(oWidth), height: CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .JSONString(let oFileUrl) = rawOriginalImage {
            self.originalURL = NSURL(string: oFileUrl)
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
    /// - parameter callback: Block to call when the temporary URL was fetched from the server.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func temporaryURL(callback: (Result<NSURL, IONError> -> Void)) {
        guard let myURL = self.url else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        IONRequest.postJSON("tokenize", queryParameters: nil, body: ["url" : myURL.absoluteString]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json,
                let rawURL = dict["url"],
                case .JSONString(let urlString) = rawURL else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
            }

            guard let url = NSURL(string: urlString) else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }

            responseQueueCallback(callback, parameter: .Success(url))
        }
    }


    /// Image url for `CanLoadImage` protocol
    public var imageURL: NSURL? {
        return self.url
    }


    /// Original image url for `CanLoadImage` protocol
    public var originalImageURL: NSURL? {
        return self.originalURL
    }
}


/// Image extension to IONPage
extension IONPage {

    /// Create thumbnail `CGImage` for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter size: The desired size of the thumbnail image
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the preview image was created.
    ///                       Provides `Result.Success` containing an `CGImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func thumbnail(name: String, size: CGSize, position: Int = 0, callback: (Result<CGImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            imageContent.thumbnail(size: size, original: false, callback: callback)
        }

        return self
    }


    #if os(iOS)
    /// Allocate `UIImage` for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the image was loaded.
    ///                       Provides `Result.Success` containing an `UIImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func image(name: String, position: Int = 0, callback: (Result<UIImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            imageContent.image(callback: callback)
        }

        return self
    }


    /// Allocate `UIImage` for named outlet (original unmodified image) async
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the original images was loaded.
    ///                       Provides `Result.Success` containing an `UIImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func originalImage(name: String, position: Int = 0, callback: (Result<UIImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            imageContent.originalImage(callback)
        }

        return self
    }
    #endif


    #if os(OSX)
    /// Allocate `NSImage` for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter callback: Block to call when the original images was loaded.
    ///                       Provides `Result.Success` containing an `NSImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func image(name: String, position: Int = 0, callback: (Result<NSImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            imageContent.image(callback: callback)
        }

        return self
    }


    /// Allocate `NSImage` for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter callback: Block to call when the original images was loaded.
    ///                       Provides `Result.Success` containing an `NSImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func originalImage(name: String, position: Int = 0, callback: (Result<NSImage, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            imageContent.originalImage(callback)
        }

        return self
    }
    #endif
}
