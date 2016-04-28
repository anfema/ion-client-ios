//
//  collection+download.swift
//  ion-client
//
//  Created by Johannes Schriewer on 27/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Tarpit
import DEjson
import iso_rfc822_date


extension IONCollection {
    private var lastUpdatedIdentifier: String {
        return "ION.collection.lastUpdated"
    }
    
    /// Last download of the complete collection
    public var lastCompleteUpdate: NSDate? {
        get {
            let prefs = NSUserDefaults.standardUserDefaults()
            
            guard let dict = prefs.objectForKey(self.lastUpdatedIdentifier) as? [String: NSDate] else {
                return nil
            }
            
            return dict[self.identifier]
        }
        
        set (newValue) {
            let prefs = NSUserDefaults.standardUserDefaults()
            var dict: [String: NSDate] = (prefs.objectForKey(self.lastUpdatedIdentifier) as? [String: NSDate]) ?? [:]
            
            dict[self.identifier] = newValue
            
            prefs.setObject(dict, forKey: self.lastUpdatedIdentifier)
            prefs.synchronize()
        }
    }
    
    /// Download an archive of a complete collection
    ///
    /// - parameter callback: Callback to call when the download finished or errored (parameter is success state)
    /// - returns: Collection for chaining
    public func download(callback: (Bool -> Void)) -> IONCollection {
        dispatch_async(self.workQueue) {
            guard let archiveURL = self.archiveURL else {
                responseQueueCallback(callback, parameter: false)
                return
            }

            var q = [String: String]()
            var url: String = archiveURL
            
            // Workaround for bug in Alamofire which does not append queryparameters to an URL that already has some
            if let dt = self.lastCompleteUpdate {
                if archiveURL.containsString("?") {
                    url += "&lastUpdated=\(dt.isoDateString())"
                } else {
                    q["lastUpdated"] = dt.isoDateString()
                }
            }
            
            IONRequest.fetchBinary(url, queryParameters: q, cached: ION.config.cacheBehaviour(.Ignore), checksumMethod:"null", checksum: "") { result in
                guard case .Success(let filename) = result else {
                    responseQueueCallback(callback, parameter: false)
                    return
                }
                
                if filename.isEmpty {
                    responseQueueCallback(callback, parameter: true)
                    return
                }

                dispatch_async(self.workQueue) {
                    let result = self.unpackToCache(filename)
                    dispatch_async(ION.config.responseQueue){
                        if result == true {
                            self.lastCompleteUpdate = NSDate()
                            ION.resetMemCache()
                            
                            for (_, collection) in ION.collectionCache where collection.identifier == self.identifier {
                                ION.config.lastOnlineUpdate[collection.identifier] = self.lastCompleteUpdate
                            }
                        }
                        callback(result)
                    }
                }
            }
        }
        
        return self
    }
    
    
    private func unpackToCache(filename: String) -> Bool {
        var index = [JSONObject]()
        
        defer {
            IONRequest.saveCacheDB()
        }
        
        do {
            let tar = try TarFile(fileName: filename)
            
            while let file = try tar.extractFile() {
                if file.filename == "index.json" {
                    guard let jsonString = NSString(data: file.data, encoding: NSUTF8StringEncoding) else {
                        return false
                    }
                    
                    let indexDB = JSONDecoder(jsonString as String).jsonObject
                    
                    guard case .JSONArray(let i) = indexDB else {
                        return false
                    }
                    
                    index = i
                } else {
                    var found: Int? = nil
                    
                    for (idx, item) in index.enumerate() {
                        guard case .JSONDictionary(let dict) = item else {
                            return false
                        }

                        guard let rawName = dict["name"], rawURL = dict["url"],
                              case .JSONString(let filename) = rawName,
                              case .JSONString(let url) = rawURL else {
                                return false
                        }
                        
                        var checksum: String? = nil
                        
                        if let dictChecksum = dict["checksum"] {
                            if case .JSONString(let ck) = dictChecksum {
                                checksum = ck
                            }
                        }
                        
                        if filename == file.filename {
                            IONRequest.saveToCache(file.data, url: url, checksum: checksum, last_updated: file.mtime)
                            found = idx
                            break
                        }
                    }
                    
                    if let found = found {
                        index.removeAtIndex(found)
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