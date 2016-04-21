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
public class IONFileContent: IONContent, CanLoadImage {
    /// mime type of file
    public var mimeType:String
    
    /// file name
    public var fileName:String
    
    /// file size in bytes
    public var size:Int = 0
    
    /// checksumming method used
    public var checksumMethod:String = "null"

    /// checksum as hex encoded string
    public var checksum:String = ""
    
    /// url to file
    public var url:NSURL?
    
    /// is this a valid file
    public var isValid = false
    
    /// Initialize file content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized file content object
    override init(json:JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType = dict["mime_type"], rawName = dict["name"], rawFileSize = dict["file_size"],
            rawChecksum = dict["checksum"], rawFile = dict["file"],
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
    /// - parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
    public func data(callback: (Result<NSData, IONError> -> Void)) {
        guard self.isValid else {
            return
        }
        
        guard let url = self.url else {
            return
        }
        
        IONRequest.fetchBinary(url.URLString, queryParameters: nil, cached: ION.config.cacheBehaviour(.Prefer),
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
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
    
    /// Get a temporary valid url for this media file
    ///
    /// - parameter callback: block to call with the temporary URL, will not be called if there was an error while
    ///                       fetching the URL from the server
    public func temporaryURL(callback: (NSURL -> Void)) {
        guard let myURL = self.url else {
            return
        }
        IONRequest.postJSON("tokenize", queryParameters: nil, body: ["url" : myURL.absoluteString ]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json where dict["url"] != nil,
                case .JSONString(let urlString) = dict["url"]! else {
                    return
            }
            
            guard let url = NSURL(string: urlString) else {
                return
            }
            
            responseQueueCallback(callback, parameter: url)
        }
    }
    
    /// image url for `CanLoadImage`
    public var imageURL:NSURL? {
        if self.mimeType.hasPrefix("image/") {
            return self.url
        }
        return nil
    }
    
    /// original image url for `CanLoadImage`, always nil
    public var originalImageURL:NSURL? {
        return nil
    }

}

/// File data extension to IONPage
extension IONPage {
    
    /// Fetch data for file async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func fileData(name: String, position: Int = 0, callback: (Result<NSData, IONError> -> Void)) -> IONPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error!))
                return
            }
            if case let content as IONFileContent = content {
                content.data(callback)
            }
        }
        return self
    }
}
