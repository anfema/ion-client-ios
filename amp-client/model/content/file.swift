//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import UIKit
import DEjson


public class AMPFileContent : AMPContentBase {
    var mimeType:String!
    var fileName:String!
    var size:Int        = 0
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
        self.checksum = checksum
        self.url      = NSURL(string: fileUrl)
    }
    
    func data() -> NSData? {
        // TODO: fetch data from cache
        return nil
    }
}

extension AMPPage {
    public func fileData(name: String) -> NSData? {
        if let content = self.outlet(name) {
            if case .File(let file) = content {
                return file.data()
            }
        }
        return nil
    }
    
    public func fileData(name: String, callback: (NSData -> Void)) {
        self.outlet(name) { content in
            if case .File(let file) = content {
                if let data = file.data() {
                    callback(data)
                }
            }
        }
    }
}
