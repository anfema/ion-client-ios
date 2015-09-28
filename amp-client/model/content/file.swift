//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPFileContent : AMPContentBase {
    var mimeType:String!
    var fileName:String!
    var size:Int        = 0
    var checksumMethod:String!
    var checksum:String!
    var url:NSURL!
    
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
    public func fileData(name: String, callback: (NSData -> Void)) {
        self.outlet(name) { content in
            if case .File(let file) = content {
                file.data(callback)
            }
        }
    }
}
