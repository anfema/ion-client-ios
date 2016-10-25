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
import DEjson


/// Media content, may be image, audio or video content
public class IONMediaContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {

    /// Original file name
    public var filename: String

    /// MIME type of media file
    public var mimeType: String

    /// Dimensions of the media file if applicable
    public var size = CGSize.zero

    /// File size in bytes
    public var fileSize = 0

    /// Method used for checksum calculation
    public var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    public var checksum: String = ""

    /// Length in seconds of the media file if applicable
    public var length: Float = 0.0

    /// URL to the media file
    public var url: NSURL?

    /// Original media file mime type
    public var originalMimeType: String

    /// Dimensions of the original media file if applicable
    public var originalSize = CGSize.zero

    /// Original media file size in bytes
    public var originalFileSize = 0

    /// Original method used for checksum calculation
    public var originalChecksumMethod: String = "null"

    /// Original checksum as hexadecimal encoded string
    public var originalChecksum: String = ""

    /// Length in seconds of the original media file if applicable
    public var originalLength: Float = 0.0

    /// URL to the original file
    public var originalURL: NSURL?

    /// If the media file is valid or not
    public var isValid = false


    /// Initialize media content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized media content object
    ///
    /// - throws: `IONError.JSONObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }

        guard let rawName           = dict["name"],
            let rawMimeType         = dict["mime_type"],
            let rawOriginalMimeType = dict["original_mime_type"],
            let rawFile             = dict["file"],
            let rawOriginalFile     = dict["original_file"],
            let rawWidth            = dict["width"],
            let rawHeight           = dict["height"],
            let rawOriginalWidth    = dict["original_width"],
            let rawOriginalHeight   = dict["original_height"],
            let rawFileSize         = dict["file_size"],
            let rawOriginalFileSize = dict["original_file_size"],
            let rawChecksum         = dict["checksum"],
            let rawOriginalChecksum = dict["original_checksum"],
            let rawLength           = dict["length"],
            let rawOriginalLength   = dict["original_length"],
            case .JSONString(let name)      = rawName,
            case .JSONString(let mimeType)  = rawMimeType,
            case .JSONString(let oMimeType) = rawOriginalMimeType,
            case .JSONNumber(let width)     = rawWidth,
            case .JSONNumber(let height)    = rawHeight,
            case .JSONNumber(let oWidth)    = rawOriginalWidth,
            case .JSONNumber(let oHeight)   = rawOriginalHeight,
            case .JSONNumber(let fileSize)  = rawFileSize,
            case .JSONNumber(let oFileSize) = rawOriginalFileSize,
            case .JSONNumber(let length)    = rawLength,
            case .JSONNumber(let oLength)   = rawOriginalLength else {
                throw IONError.InvalidJSON(json)
        }

        self.filename = name
        self.mimeType = mimeType
        self.size     = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.fileSize = Int(fileSize)

        if case .JSONString(let fileUrl) = rawFile {
            self.url     = NSURL(string: fileUrl)
            self.isValid = true
        }

        if case .JSONString(let checksum)  = rawChecksum {
            let checksumParts = checksum.componentsSeparatedByString(":")

            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }

        self.length = Float(length)

        self.originalMimeType = oMimeType
        self.originalSize     = CGSize(width: CGFloat(oWidth), height: CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .JSONString(let oFileUrl) = rawOriginalFile {
            self.originalURL = NSURL(string: oFileUrl)
        }

        if case .JSONString(let oChecksum) = rawOriginalChecksum {
            let originalChecksumParts = oChecksum.componentsSeparatedByString(":")

            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }

        self.originalLength = Float(oLength)

        try super.init(json: json)
    }


    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - parameter callback: Block to call when the file data becomes available.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func data(callback: (Result<NSData, IONError> -> Void)) {
        self.cachedURL { result in
            guard case .Success(let url) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            do {
                let data = try NSData(contentsOfURL: url, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                responseQueueCallback(callback, parameter: .Success(data))
            } catch {
                responseQueueCallback(callback, parameter: .Failure(.NoData(error)))
            }
        }
    }


    /// Download the file and give back the URL
    ///
    /// - parameter callback: Block to call when the download of the file has finished.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func cachedURL(callback: (Result<NSURL, IONError> -> Void)) {
        guard let url = self.url else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }

            responseQueueCallback(callback, parameter: .Success(NSURL(fileURLWithPath: filename)))
        }
    }


    /// Get a temporary valid url for this media file
    ///
    /// - parameter callback: Block to call when the temporary URL was fetched from the server.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func temporaryURL(callback: (Result<NSURL, IONError> -> Void)) {
        guard let urlString = self.url?.absoluteString else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        IONRequest.postJSON("tokenize", queryParameters: nil, body: ["url" : urlString]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json,
                let rawURL = dict["url"],
                case .JSONString(let urlString) = rawURL,
                let url = NSURL(string: urlString) else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
            }

            responseQueueCallback(callback, parameter: .Success(url))
        }
    }


    /// Image url for `CanLoadImage` protocol
    public var imageURL: NSURL? {
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }

        return nil
    }


    /// Original image url for `CanLoadImage` protocol
    public var originalImageURL: NSURL? {
        if self.originalMimeType.hasPrefix("image/") {
            return self.originalURL
        }

        return nil
    }
}


/// Media content extensions to IONPage
extension IONPage {

    /// Fetch URL for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `NSURL` if the outlet is a `URLProvider`
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func mediaURL(name: String, position: Int = 0) -> Result<NSURL, IONError> {
        let result = self.outlet(name, position: position)

        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }

        guard case let urlProvider as URLProvider = content else {
            return .Failure(.OutletIncompatible)
        }

        guard let url = urlProvider.url else {
            return .Failure(.OutletEmpty)
        }

        return .Success(url)
    }


    /// Fetch URL for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the media outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func mediaURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.mediaURL(name, position: position))
        }

        return self
    }


    /// Fetch locally cached URL for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the media file was downloaded.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func cachedMediaURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let mediaContent as IONMediaContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            mediaContent.cachedURL { result in
                responseQueueCallback(callback, parameter: result)
            }
        }

        return self
    }


    /// Fetch temporary valid URL for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the temporary URL was fetched from the server.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func temporaryURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let urlProvider as TemporaryURLProvider = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            urlProvider.temporaryURL { result in
                responseQueueCallback(callback, parameter: result)
            }
        }

        return self
    }


    /// Fetch data for media file async
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the data of the media file becomes available.
    ///                       Provides `Result.Success` containing an `NSData` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    public func mediaData(name: String, position: Int = 0, callback: (Result<NSData, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            guard case let mediaContent as IONMediaContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }

            mediaContent.data(callback)
        }

        return self
    }
}
