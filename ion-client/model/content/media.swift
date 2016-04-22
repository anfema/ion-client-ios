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
public class IONMediaContent: IONContent, CanLoadImage {
    
    // original file name
    public var filename:String
    
    /// mime type of media file
    public var mimeType:String
    
    /// dimensions of the media file if applicable
    public var size = CGSizeZero
    
    /// file size in bytes
    public var fileSize = 0

    /// checksumming method used
    public var checksumMethod:String = "null"

    /// checksum of the file
    public var checksum:String = ""
    
    /// length in seconds of the media file if applicable
    public var length = Float(0.0)
    
    /// url to the media file
    public var url:NSURL?
    
    /// original media file mime type
    public var originalMimeType:String
    
    /// dimensions of the original media file if applicable
    public var originalSize = CGSizeZero

    /// original media file size in bytes
    public var originalFileSize = 0
    
    /// checksumming method used
    public var originalChecksumMethod:String = "null"
    
    /// checksum of the original file
    public var originalChecksum:String = ""
    
    /// length in seconds of the original media file if applicable
    public var originalLength = Float(0.0)

    /// url to the original file
    public var originalURL:NSURL?
    
    /// is this a valid media content object
    public var isValid = false
    
    /// Initialize media content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized media content object
    override init(json:JSONObject) throws {
        
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawName = dict["name"], rawMimeType = dict["mime_type"], rawOriginalMimeType = dict["original_mime_type"], rawFile = dict["file"],
            rawOriginalFile = dict["original_file"], rawWidth = dict["width"], rawHeight = dict["height"],
            rawOriginalWidth = dict["original_width"], rawOriginalHeight = dict["original_height"], rawFileSize = dict["file_size"],
            rawOriginalFileSize = dict["original_file_size"], rawChecksum = dict["checksum"], rawOriginalChecksum = dict["original_checksum"],
            rawLength = dict["length"], rawOriginalLength = dict["original_length"],
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
        self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
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
        self.length   = Float(length)
        
        self.originalMimeType = oMimeType
        self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
        self.originalFileSize = Int(oFileSize)
        if case .JSONString(let oFileUrl) = rawOriginalFile {
            self.originalURL      = NSURL(string: oFileUrl)
        }
        
        if case .JSONString(let oChecksum) = rawOriginalChecksum {
            let originalChecksumParts = oChecksum.componentsSeparatedByString(":")
            if originalChecksumParts.count > 1 {
                self.originalChecksumMethod = originalChecksumParts[0]
                self.originalChecksum = originalChecksumParts[1]
            }
        }
        self.originalLength   = Float(oLength)

        try super.init(json: json)
    }
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
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
    /// - parameter callback: block to call when the download has finished, will not be called if there was an error
    public func cachedURL(callback: (Result<NSURL, IONError> -> Void)) {
        guard let url = self.url else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
                return
            }
                
            responseQueueCallback(callback, parameter: .Success(NSURL(fileURLWithPath: filename)))
        }
    }
    
    /// Get a temporary valid url for this media file
    ///
    /// - parameter callback: block to call with the temporary URL, will not be called if there was an error while
    ///                       fetching the URL from the server
    public func temporaryURL(callback: (Result<NSURL, IONError> -> Void)) {
        guard let url = self.url else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        IONRequest.postJSON("tokenize", queryParameters: nil, body: ["url" : url.absoluteString ]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json where dict["url"] != nil,
                case .JSONString(let urlString) = dict["url"]!,
                let url = NSURL(string: urlString) else {
                    return
            }

            responseQueueCallback(callback, parameter: .Success(url))
        }
    }
    
    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }
        return nil
    }
    
    /// original image url for `CanLoadImage`
    public var originalImageURL:NSURL? {
        if self.originalMimeType.hasPrefix("image/") {
            return self.originalURL
        }
        return nil
    }
}

/// Media content extensions to IONPage
extension IONPage {
    
    /// Fetch URL from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `NSURL` object if the outlet was a media outlet and the page was already cached, else nil
    public func mediaURL(name: String, position: Int = 0) -> Result<NSURL, IONError> {
        let result = self.outlet(name, position: position)
        if case .Success(let content) = result {
            if case let content as IONMediaContent = content,
               let url = content.url {
                return .Success(url)
            }

            if case let content as IONFileContent = content,
               let url = content.url {
                return .Success(url)
            }
            
            return .Failure(.OutletIncompatible)
        }
        return .Failure(.OutletNotFound(name))
    }

    /// Fetch URL from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONMediaContent = content {
                if let url = content.url {
                    responseQueueCallback(callback, parameter: .Success(url))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.OutletEmpty))
                }
            } else if case let content as IONFileContent = content {
                if let url = content.url {
                    responseQueueCallback(callback, parameter: .Success(url))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.OutletEmpty))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }

    /// Fetch locally cached URL from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func cachedMediaURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        // TODO: Test this
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            if case let content as IONMediaContent = content {
                content.cachedURL { result in
                    guard case .Success(let url) = result else {
                        responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                        return
                    }

                    responseQueueCallback(callback, parameter: .Success(url))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }

    /// Fetch temporary valid URL from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the media object becomes available, will not be called if the outlet
    ///                       is not a media outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func temporaryURL(name: String, position: Int = 0, callback: (Result<NSURL, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            if case let content as IONMediaContent = content {
                content.temporaryURL { result in
                    guard case .Success(let url) = result else {
                        responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                        return
                    }
                    responseQueueCallback(callback, parameter: .Success(url))
                }
            } else if case let content as IONFileContent = content {
                content.temporaryURL { url in
                    responseQueueCallback(callback, parameter: .Success(url))
                }
            } else if case let content as IONImageContent = content {
                content.temporaryURL { url in
                    responseQueueCallback(callback, parameter: .Success(url))
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
    
   
    /// Fetch data for media file async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func mediaData(name: String, position: Int = 0, callback: (Result<NSData, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }

            if case let content as IONMediaContent = content {
                content.data(callback)
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletIncompatible))
            }
        }
        return self
    }
}