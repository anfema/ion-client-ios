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
    private var lastUpdatedIdentifier: String {
        return "lastUpdated-\(self.identifier)"
    }
    
    public var lastCompleteUpdate: NSDate? {
        get {
            let prefs = NSUserDefaults.standardUserDefaults()
            if let dt = prefs.valueForKey(self.lastUpdatedIdentifier) as? NSDate {
                return dt
            }
            return nil
        }
        
        set (newValue) {
            let prefs = NSUserDefaults.standardUserDefaults()
            if let v = newValue {
                prefs.setObject(v, forKey: self.lastUpdatedIdentifier)
            } else {
                prefs.removeObjectForKey(self.lastUpdatedIdentifier)
            }
            prefs.synchronize()
        }
    }
    
    public func download(callback: (Bool -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            
            var q = [String:String]()
            if let dt = self.lastCompleteUpdate {
                q["lastUpdate"] = dt.isoDateString
            }
            
            AMPRequest.fetchBinary(self.archiveURL, queryParameters: q, cached: false,
                checksumMethod:"null", checksum: "") { result in
                    guard case .Success(let filename) = result else {
                        dispatch_async(AMP.config.responseQueue) {
                            callback(false)
                        }
                        return
                    }

                    dispatch_async(self.workQueue) {
                        let result = self.unpackToCache(filename)
                        dispatch_async(AMP.config.responseQueue){
                            if result == true {
                                self.lastCompleteUpdate = NSDate()
                                AMP.resetMemCache()
                                for (_, collection) in AMP.collectionCache where collection.identifier == self.identifier {
                                    AMP.config.lastOnlineUpdate[collection.identifier] = self.lastCompleteUpdate
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
            AMPRequest.saveCacheDB()
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
                            AMPRequest.saveToCache(file.data, url: url, checksum: checksum, last_updated: file.mtime)
                            found = idx
                            break
                        }
                    }
                    if found != nil {
                        index.removeAtIndex(found!)
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