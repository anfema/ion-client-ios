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
public class IONFileContent: IONContent, CanLoadImage, URLProvider, TemporaryURLProvider {
    
    /// MIME type of the file
    public var mimeType: String
    
    /// File name
    public var fileName: String
    
    /// File size in bytes
    public var size: Int = 0
    
    /// Method used for checksum calculation
    public var checksumMethod: String = "null"

    /// Checksum as hexadecimal encoded string
    public var checksum: String = ""
    
    /// URL to the file
    public var url: NSURL?
    
    /// If the file is valid or not
    public var isValid = false
    
    
    /// Initialize file content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized file content object
    override init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType   = dict["mime_type"],
            let rawName         = dict["name"],
            let rawFileSize     = dict["file_size"],
            let rawChecksum     = dict["checksum"],
            let rawFile         = dict["file"],
            case .JSONString(let mimeType) = rawMimeType,
            case .JSONString(let fileName) = rawName,
            case .JSONNumber(let size)     = rawFileSize else {
                throw IONError.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.fileName = fileName
        self.size     = Int(size)
        
        if case .JSONString(let checksum)  = rawChecksum {
            let checksumParts = checksum.componentsSeparatedByString(":")
            
            if checksumParts.count > 1 {
                self.checksumMethod = checksumParts[0]
                self.checksum = checksumParts[1]
            }
        }
        
        if case .JSONString(let fileUrl) = rawFile {
            self.url     = NSURL(string: fileUrl)
            self.isValid = true
        }
        
        try super.init(json: json)
    }
    
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - parameter callback: Block to call when file data gets available.
    ///                       Provides `Result.Success` containing `NSData` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    public func data(callback: (Result<NSData, IONError> -> Void)) {
        guard let url = self.url where self.isValid else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod: self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            do {
                let data = try NSData(contentsOfFile: filename, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                responseQueueCallback(callback, parameter: .Success(data))
            } catch {
                responseQueueCallback(callback, parameter: .Failure(.NoData(error)))
            }
        }
    }
    
    
    /// Get a temporarily valid url for this file
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
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }
        
        return nil
    }
    
    
    /// Original image url for `CanLoadImage` protocol, always nil
    public var originalImageURL: NSURL? {
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
    public func fileData(name: String, position: Int = 0, callback: (Result<NSData, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            guard case let fileContent as IONFileContent = content else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
                return
            }
            
            fileContent.data(callback)
        }
        
        return self
    }
}
