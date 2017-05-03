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
open class IONMediaContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {

    /// Original file name
    open var filename: String

    /// MIME type of media file
    open var mimeType: String

    /// Dimensions of the media file if applicable
    open var size = CGSize.zero

    /// File size in bytes
    open var fileSize = 0

    /// Method used for checksum calculation
    open var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    open var checksum: String = ""

    /// Length in seconds of the media file if applicable
    open var length: Float = 0.0

    /// URL to the media file
    open var url: URL?

    /// Original media file mime type
    open var originalMimeType: String

    /// Dimensions of the original media file if applicable
    open var originalSize = CGSize.zero

    /// Original media file size in bytes
    open var originalFileSize = 0

    /// Original method used for checksum calculation
    open var originalChecksumMethod: String = "null"

    /// Original checksum as hexadecimal encoded string
    open var originalChecksum: String = ""

    /// Length in seconds of the original media file if applicable
    open var originalLength: Float = 0.0

    /// URL to the original file
    open var originalURL: URL?

    /// If the media file is valid or not
    open var isValid = false


    /// Initialize media content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized media content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
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
            case .jsonString(let name)      = rawName,
            case .jsonString(let mimeType)  = rawMimeType,
            case .jsonString(let oMimeType) = rawOriginalMimeType,
            case .jsonNumber(let width)     = rawWidth,
            case .jsonNumber(let height)    = rawHeight,
            case .jsonNumber(let oWidth)    = rawOriginalWidth,
            case .jsonNumber(let oHeight)   = rawOriginalHeight,
            case .jsonNumber(let fileSize)  = rawFileSize,
            case .jsonNumber(let oFileSize) = rawOriginalFileSize,
            case .jsonNumber(let length)    = rawLength,
            case .jsonNumber(let oLength)   = rawOriginalLength else {
                throw IONError.invalidJSON(json)
        }

        self.filename = name
        self.mimeType = mimeType
        self.size     = CGSize(width: CGFloat(width), height: CGFloat(height))
        self.fileSize = Int(fileSize)

        if case .jsonString(let fileUrl) = rawFile {
            self.url     = URL(string: fileUrl)
            self.isValid = true
        }

        if case .jsonString(let checksum)  = rawChecksum {
            let checksumParts = checksum.components(separatedBy: ":")

            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }

        self.length = Float(length)

        self.originalMimeType = oMimeType
        self.originalSize     = CGSize(width: CGFloat(oWidth), height: CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)

        if case .jsonString(let oFileUrl) = rawOriginalFile {
            self.originalURL = URL(string: oFileUrl)
        }

        if case .jsonString(let oChecksum) = rawOriginalChecksum {
            let originalChecksumParts = oChecksum.components(separatedBy: ":")

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
    open func data(_ callback: @escaping ((Result<Data>) -> Void)) {
        self.cachedURL { result in
            guard case .success(let url) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            do {
                let data = try Data(contentsOf: url, options: NSData.ReadingOptions.mappedIfSafe)
                responseQueueCallback(callback, parameter: .success(data))
            } catch {
                responseQueueCallback(callback, parameter: .failure(IONError.noData(error)))
            }
        }
    }


    /// Download the file and give back the URL
    ///
    /// - parameter callback: Block to call when the download of the file has finished.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    open func cachedURL(_ callback: @escaping ((Result<URL>) -> Void)) {
        guard let url = self.url else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        IONRequest.fetchBinary(fromURL: url.absoluteString, queryParameters: nil, cacheBehaviour: ION.config.cacheBehaviour(.prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
            guard case .success(let filename) = result else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            responseQueueCallback(callback, parameter: .success(URL(fileURLWithPath: filename)))
        }
    }


    /// Get a temporary valid url for this media file
    ///
    /// - parameter callback: Block to call when the temporary URL was fetched from the server.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    open func temporaryURL(_ callback: @escaping ((Result<URL>) -> Void)) {
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
                case .jsonString(let urlString) = rawURL,
                let url = URL(string: urlString) else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
            }

            responseQueueCallback(callback, parameter: .success(url))
        }
    }


    /// Image url for `CanLoadImage` protocol
    open var imageURL: URL? {
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }

        return nil
    }


    /// Original image url for `CanLoadImage` protocol
    open var originalImageURL: URL? {
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
    public func mediaURL(_ name: String, atPosition position: Int = 0) -> Result<URL> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let urlProvider as URLProvider = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let url = urlProvider.url else {
            return .failure(IONError.outletEmpty)
        }

        return .success(url)
    }


    /// Fetch URL for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the media outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSURL` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func mediaURL(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<URL>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.mediaURL(name, atPosition: position))
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
    @discardableResult public func cachedMediaURL(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<URL>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let mediaContent as IONMediaContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
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
    @discardableResult public func temporaryURL(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<URL>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let urlProvider as TemporaryURLProvider = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
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
    @discardableResult public func mediaData(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Data>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let mediaContent as IONMediaContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
                return
            }

            mediaContent.data(callback)
        }

        return self
    }
}


public extension Content {

    /// Provides a media content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    public func mediaContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONMediaContent? {
        return self.content(identifier, at: position)
    }


    public func mediaContents(_ identifier: OutletIdentifier) -> [IONMediaContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONMediaContent] ?? nil)
    }


    public func mediaURL(_ identifier: OutletIdentifier, at position: Position = 0) -> URL? {
        return mediaContent(identifier, at: position)?.url
    }
}
