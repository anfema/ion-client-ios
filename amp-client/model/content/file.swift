//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPFileContent : AMPContent {
    var mimeType:String!        /// mime type of file
    var fileName:String!        /// file name
    var size:Int = 0            /// file size in bytes
    var checksumMethod:String!  /// checksumming method used
    var checksum:String!        /// checksum as hex encoded string
    var url:NSURL!              /// url to file
    
    /// Initialize file content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized file content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["mime_type"] != nil) && (dict["name"] != nil) && (dict["file_size"] != nil) &&
            (dict["checksum"] != nil) && (dict["file"] != nil),
            case .JSONString(let mimeType) = dict["mime_type"]!,
            case .JSONString(let fileName) = dict["name"]!,
            case .JSONNumber(let size)     = dict["file_size"]!,
            case .JSONString(let checksum) = dict["checksum"]!,
            case .JSONString(let fileUrl)  = dict["file"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.mimeType = mimeType
        self.fileName = fileName
        self.size     = Int(size)
        let checksumParts = checksum.componentsSeparatedByString(":")
        self.checksumMethod = checksumParts[0]
        self.checksum = checksumParts[1]
        self.url      = NSURL(string: fileUrl)
    }
    
    /// Load the file binary data and return memory mapped `NSData`
    ///
    /// - Parameter callback: block to call when file data gets available, will not be called if there was an error
    ///                       while downloading or fetching the file data from the cache
    public func data(callback: (NSData -> Void)) {
        // TODO: Cache invalidation
        AMPRequest.fetchBinary(self.url.URLString, queryParameters: nil) { result in
            guard case .Success(let filename) = result else {
                return
            }
            do {
                let data = try NSData(contentsOfFile: filename, options: NSDataReadingOptions.DataReadingMappedIfSafe)
                dispatch_async(AMP.config.responseQueue) {
                    callback(data)
                }
            } catch {
                print("AMP: Could not read file \(filename)")
            }
        }
    }
}

extension AMPPage {
    
    /// Fetch data for file async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the data becomes available, will not be called if the outlet
    ///                       is not a file outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func fileData(name: String, callback: (NSData -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPFileContent = content {
                content.data(callback)
            }
        }
        return self
    }
}
