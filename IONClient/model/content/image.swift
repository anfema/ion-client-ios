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
import UIKit.UIImage

/// Image content, has OS specific image loading functionality
open class IONImageContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {

    /// MIME type of the image
    open var mimeType: String?

    /// Dimensions of the image
    open var size: CGSize = CGSize.zero

    /// File size in bytes
    open var fileSize: Int = 0

    /// URL of the image
    open var url: URL?

    /// Original image mime type
    open var originalMimeType: String?

    /// Original image dimensions
    open var originalSize: CGSize = CGSize.zero

    /// Original image file size
    open var originalFileSize: Int = 0

    /// Original image URL
    open var originalURL: URL?

    /// Image translation before cropping to final size
    open var translation: CGPoint = CGPoint.zero

    /// Image scale factor before cropping
    open var scale: Float = 1.0

    /// Method used for checksum calculation
    open var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    open var checksum: String = ""

    /// Original method used for checksum calculation
    open var originalChecksumMethod: String = "null"

    /// Original checksum as hexadecimal encoded string
    open var originalChecksum: String = ""

    /// If the image file is valid or not
    open var isValid = false


    /// Initialize image content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized image content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
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
            case .jsonString(let mimeType)  = rawMimeType,
            case .jsonString(let oMimeType) = rawOriginalMimeType,
            case .jsonNumber(let width)     = rawWidth,
            case .jsonNumber(let height)    = rawHeight,
            case .jsonNumber(let oWidth)    = rawOriginalWidth,
            case .jsonNumber(let oHeight)   = rawOriginalHeight,
            case .jsonNumber(let fileSize)  = rawFileSize,
            case .jsonNumber(let oFileSize) = rawOriginalFileSize,
            case .jsonNumber(let scale)     = rawScale,
            case .jsonNumber(let transX)    = rawTranslationX,
            case .jsonNumber(let transY)    = rawTranslationY else {
                throw IONError.invalidJSON(json)
        }

        self.mimeType = mimeType
        self.size     = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.fileSize = Int(fileSize)

        if case .jsonString(let fileUrl) = rawImage {
            self.url = URL(string: fileUrl)
            self.isValid = true
        }

        self.translation = CGPoint(x: CGFloat(transX), y: CGFloat(transY))
        self.scale       = Float(scale)

        self.originalMimeType = oMimeType
        self.originalSize     = CGSize(width: CGFloat(oWidth), height: CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .jsonString(let oFileUrl) = rawOriginalImage {
            self.originalURL = URL(string: oFileUrl)
        }

        if case .jsonString(let checksum)  = rawChecksum {

            let checksumParts = checksum.components(separatedBy: ":")

            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }

        if case .jsonString(let oChecksum) = rawOriginalChecksum {
            let originalChecksumParts = oChecksum.components(separatedBy: ":")

            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }

        try super.init(json: json)
    }

    init(url: URL, outletIdentifier: OutletIdentifier) {
        super.init(outletIdentifier: outletIdentifier)
    }

    /// Get a temporary valid url for this image file
    ///
    /// - parameter callback: Block to call when the temporary URL was fetched from the server.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    open func temporaryURL(_ callback: @escaping ((Result<URL, Error>) -> Void)) {
        guard let urlString = self.url?.absoluteString else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        IONRequest.postJSON(toEndpoint: "tokenize", queryParameters: nil, body: ["url": urlString as AnyObject]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .jsonDictionary(let dict) = json,
                let rawURL = dict["url"],
                case .jsonString(let urlString) = rawURL else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
            }

            guard let url = URL(string: urlString) else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            responseQueueCallback(callback, parameter: .success(url))
        }
    }


    /// Image url for `CanLoadImage` protocol
    open var imageURL: URL? {
        return self.url
    }


    /// Original image url for `CanLoadImage` protocol
    open var originalImageURL: URL? {
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
    /// - returns: self for chaining
    @discardableResult public func thumbnail(_ name: String, withSize size: CGSize, atPosition position: Int = 0, callback: @escaping ((Result<CGImage, Error>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
                return
            }

            imageContent.thumbnail(withSize: size, usingOriginalDataProvider: false, callback: callback)
        }

        return self
    }

    /// Allocate `UIImage` for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the image was loaded.
    ///                       Provides `Result.Success` containing an `UIImage` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func image(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<UIImage, Error>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
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
    /// - returns: self for chaining
    @discardableResult public func originalImage(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<UIImage, Error>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let imageContent as IONImageContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
                return
            }

            imageContent.originalImage(callback)
        }

        return self
    }
}


public extension Content {

    /// Provides a image content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func imageContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONImageContent? {
        return self.content(identifier, at: position)
    }


    func imageContents(_ identifier: OutletIdentifier) -> [IONImageContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONImageContent] ?? nil)
    }

    func image(_ identifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()

        guard let imageContent: IONImageContent = imageContent(identifier, at: position) else {
            ION.config.responseQueue.async { asyncResult.execute(result: .failure(IONError.noData(nil))) }
            return asyncResult
        }

        imageContent.image(callback: { (result) in
            asyncResult.execute(result: result)
        })

        return asyncResult
    }


    func thumbnail(_ identifier: OutletIdentifier, at position: Position = 0, ofSize size: CGSize) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()

        guard let imageContent: IONImageContent = imageContent(identifier, at: position) else {
            ION.config.responseQueue.async { asyncResult.execute(result: .failure(IONError.noData(nil))) }
            return asyncResult
        }

        imageContent.thumbnail(withSize: size, callback: { (result) in

            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }

            asyncResult.execute(result: .success(UIImage(cgImage: image)))
        })

        return asyncResult
    }
}
