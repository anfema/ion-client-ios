//
//  collection+download.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 27/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Tarpit
import DEjson

extension AMPCollection {
    public func download(callback: (Void -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            
            AMPRequest.fetchBinary(self.archiveURL, queryParameters: [ "locale" : self.locale ], cached: false,
                checksumMethod:"null", checksum: "") { result in
                    guard case .Success(let filename) = result else {
                        return
                    }
                    
                    if self.unpackToCache(filename) {
                        dispatch_async(AMP.config.responseQueue) {
                            callback()
                        }
                    }
            }
        }
        return self
    }
    
    
    private func unpackToCache(filename: String) -> Bool {
        var indexDB: JSONObject? = nil
        
        do {
            let tar = try TarFile(fileName: filename)
            while let file = try tar.extractFile() {
                if file.filename == "index.json" {
                    guard let jsonString = NSString(data: file.data, encoding: NSUTF8StringEncoding) else {
                        return false
                    }
                    indexDB = JSONDecoder(jsonString as String).jsonObject
                } else {
                    guard let indexDB = indexDB,
                          case .JSONArray(let index) = indexDB else {
                        return false
                    }
                    for item in index {
                        guard case .JSONDictionary(let dict) = item where (dict["name"] != nil) && (dict["url"] != nil),
                              case .JSONString(let filename) = dict["name"]!,
                              case .JSONString(let url) = dict["url"]! else {
                                return false
                        }
                        var checksum: String? = nil
                        if (dict["checksum"] != nil) {
                            if case .JSONString(let ck) = dict["checksum"]! {
                                checksum = ck
                            }
                        }
                        
                        if filename == file.filename {
                            AMPRequest.saveToCache(file.data, url: url, checksum: checksum)
                            break
                        }
                    }
                }
            }
        } catch TarFile.Errors.EndOfFile {
            // ok
            return true
        } catch {
            return false
        }
        return true
    }
}