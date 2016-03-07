//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson
import Alamofire

/// File content
public class AMPFileContent : AMPContent, CanLoadImage {
    /// mime type of file
    public var mimeType:String!
    
    /// file name
    public var fileName:String!
    
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
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard let rawMimeType = dict["mime_type"], rawName = dict["name"], rawFileSize = dict["file_size"],
            rawChecksum = dict["checksum"], rawFile = dict["file"],
            case .JSONString(let mimeType) = rawMimeType,
            case .JSONString(let fileName) = rawName,
            case .JSONNumber(let size)     = rawFileSize else {
                throw AMPError.InvalidJSON(json)
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
    }
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
    public func data(callback: (Result<NSData, AMPError> -> Void)) {
        guard self.isValid else {
            return
        }
        AMPRequest.fetchBinary(self.url!.URLString, queryParameters: nil, cached: AMP.config.cacheBehaviour(.Prefer),
            checksumMethod:self.checksumMethod, checksum: self.checksum) { result in
            guard case .Success(let filename) = result else {
                return
            }
            do {
                let data = try NSData(contentsOfFile: filename, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                dispatch_async(AMP.config.responseQueue) {
                    callback(.Success(data))
                }
            } catch {
                callback(.Failure(.NoData(error)))
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
        AMPRequest.postJSON("tokenize", queryParameters: nil, body: [ "url" : myURL.absoluteString ]) { result in
            guard result.isSuccess,
                let jsonResponse = result.value,
                let json = jsonResponse.json,
                case .JSONDictionary(let dict) = json where dict["url"] != nil,
                case .JSONString(let url) = dict["url"]! else {
                    return
            }
            
            dispatch_async(AMP.config.responseQueue) {
                callback(NSURL(string: url)!)
            }
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

/// File data extension to AMPPage
extension AMPPage {
    
    /// Fetch data for file async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func fileData(name: String, position: Int = 0, callback: (Result<NSData, AMPError> -> Void)) -> AMPPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                callback(.Failure(result.error!))
                return
            }
            if case let content as AMPFileContent = content {
                content.data(callback)
            }
        }
        return self
    }
}
