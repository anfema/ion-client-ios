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


/// File content
open class IONFileContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {

    /// MIME type of the file
    open var mimeType: String

    /// File name
    open var fileName: String

    /// File size in bytes
    open var size: Int = 0

    /// Method used for checksum calculation
    open var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    open var checksum: String = ""

    /// URL to the file
    open var url: URL?

    /// If the file is valid or not
    open var isValid = false


    /// Initialize file content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized file content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawMimeType   = dict["mime_type"],
            let rawName         = dict["name"],
            let rawFileSize     = dict["file_size"],
            let rawChecksum     = dict["checksum"],
            let rawFile         = dict["file"],
            case .jsonString(let mimeType) = rawMimeType,
            case .jsonString(let fileName) = rawName,
            case .jsonNumber(let size)     = rawFileSize else {
                throw IONError.invalidJSON(json)
        }

        self.mimeType = mimeType
        self.fileName = fileName
        self.size     = Int(size)

        if case .jsonString(let checksum)  = rawChecksum {
            let checksumParts = checksum.components(separatedBy: ":")

            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }

        if case .jsonString(let fileUrl) = rawFile {
            self.url     = URL(string: fileUrl)
            self.isValid = true
        }

        try super.init(json: json)
    }


    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - parameter callback: Block to call when file data gets available.
    ///                       Provides `Result.Success` containing `NSData` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    open func data(_ callback: @escaping ((Result<Data>) -> Void)) {
        guard let url = self.url, self.isValid else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        IONRequest.fetchBinary(fromURL: url.absoluteString, queryParameters: nil, cacheBehaviour: ION.config.cacheBehaviour(.prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
            guard case .success(let filename) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: filename), options: .mappedIfSafe)
                responseQueueCallback(callback, parameter: .success(data))
            } catch {
                responseQueueCallback(callback, parameter: .failure(IONError.noData(error)))
            }
        }
    }


    /// Get a temporarily valid url for this file
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
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }

        return nil
    }


    /// Original image url for `CanLoadImage` protocol, always nil
    open var originalImageURL: URL? {
        return nil
    }
}


/// File data extension to IONPage
extension IONPage {

    /// Fetch data for file async
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the file outlet becomes available and
    ///                       the file is loaded.
    ///                       Provides `Result.Success` containing an `NSData` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func fileData(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Data>) -> Void)) -> IONPage {
        self.outlet(name, atPosition: position) { result in
            guard case .success(let content) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            guard case let fileContent as IONFileContent = content else {
                responseQueueCallback(callback, parameter: .failure(IONError.outletIncompatible))
                return
            }

            fileContent.data(callback)
        }

        return self
    }
}


public extension Content {

    /// Provides a file content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func fileContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONFileContent? {
        return self.content(identifier, at: position)
    }


    func fileContents(_ identifier: OutletIdentifier) -> [IONFileContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONFileContent] ?? nil)
    }


    func fileData(_ identifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<Data> {
        let asyncResult = AsyncResult<Data>()

        self.fileContent(identifier, at: position)?.data({ (result) in
            guard case .success(let data) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }

            asyncResult.execute(result: .success(data))
        })

        return asyncResult
    }
}
