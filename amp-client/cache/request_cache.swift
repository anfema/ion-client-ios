//
//  request.swift
//  amp-client
//
//  Created by Johannes Schriewer on 22.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

import HashExtensions
import Alamofire
import DEjson

/// Caching extension for AMPRequest
extension AMPRequest {
    // MARK: - external API
    
    /// Reset the complete AMP cache for a specific host
    ///
    /// - parameter host: host to clear cache for
    /// - parameter locale: locale to clear cache for
    public class func resetCache(host: String, locale: String = AMP.config.locale) {
        // remove complete cache dir for this host
        let fileURL = self.cacheBaseDir(host, locale: locale)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(fileURL.path!)
        } catch {
            // non-fatal, could not remove item at path, so probably path did not exist
        }
        
        // remove all entries for this host from cache db
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        
        removeCacheDBEntries(forKey: "host", value: host)
        self.saveCacheDB()
    }

    /// Reset complete AMP cache for a specific language and all hosts
    ///
    /// - parameter locale: locale to clear cache for
    public class func resetCache(locale locale: String) {
        // TODO: Write test for resetCache(locale:)

        // remove complete cache dir for this host
        let fileURL = self.cacheBaseDir(locale: locale)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(fileURL.path!)
        } catch {
            // non-fatal, could not remove item at path, so probably path did not exist
        }

        if locale == AMP.config.locale {
            // remove all entries for this locale from cache db
            self.cacheDB = []
            self.saveCacheDB()
        }
    }
    
    // MARK: - Internal API
    
    /// Internal function to fetch the cache path for a specific URL
    ///
    /// - parameter url: the URL to find in the cache
    /// - returns: Path to the cache file (may not exist)
    internal class func cacheName(url: NSURL) -> String {
        var fileURL = self.cacheBaseDir(url.host!, locale: AMP.config.locale)
        
        // try to create the path if it does not exist
        if !NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(fileURL.path!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if AMP.config.loggingEnabled {
                    print("AMP: Could not create cache dir!")
                }
            }
        }
        
        // generate cache path
        fileURL = fileURL.URLByAppendingPathComponent(url.URLString.cryptoHash(.MD5))
        return fileURL.path!
    }

    /// Internal function to fetch a cache DB entry
    ///
    /// - parameter urlString: the URL to find in the cache DB
    /// - returns: cache db entry (JSON dictionary unpacked into dictionary)
    internal class func getCacheDBEntry(urlString: String) -> [String:JSONObject]? {
        // load db if not already loaded
        if self.cacheDB == nil {
            self.loadCacheDB()
        }

        // find entry in cache db
        for case .JSONDictionary(let dict) in self.cacheDB! {
            guard let rawURL = dict["url"],
                  case .JSONString(let entryURL) = rawURL where entryURL == urlString else {
                continue
            }
            return dict
        }
        
        // nothing found
        return nil
    }

    /// Internal function to save a JSON response to the cache
    ///
    /// - parameter request: request (used for request url)
    /// - parameter result: the object to save or an error
    internal class func saveToCache(request: NSURLRequest, _ result:Result<JSONObject, AMPError>) {

        // object can only be saved if there is a request url and the status code of the response is a 200
        guard result.isSuccess,
            case .Success(let data) = result,
            let json = JSONEncoder(data).prettyJSONString else {
                return
        }
        
        do {
            // save object to disk
            let cacheName = self.cacheName(request.URL!)
            try json.writeToFile(cacheName, atomically: true, encoding: NSUTF8StringEncoding)
            
            // save object to cache DB
            self.saveToCache(request, checksumMethod: "null", checksum: "")
        } catch {
            // do nothing, could not be saved to cache -> nonfatal
        }
    }
    
    internal class func saveToCache(data: NSData, url: String, checksum:String?, last_updated:NSDate? = nil) {
        // load cache DB if not loaded yet
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        
        // fetch current timestamp truncated to maximum resolution of 1 ms
        var timestamp: Double = 0.0
        if let last_updated = last_updated {
            timestamp = trunc(last_updated.timeIntervalSince1970 * 1000.0) / 1000.0
        } else {
            timestamp = trunc(NSDate().timeIntervalSince1970 * 1000.0) / 1000.0
        }
        
        // pop current cache DB entry
        var obj:[String:JSONObject] = self.getCacheDBEntry(url) ?? [:]
        self.removeCacheDBEntries(withURL: url)
        
        let parsedURL = NSURL(string: url)!
        let hash = url.cryptoHash(.MD5)
        
        
        var filename = self.cacheBaseDir(parsedURL.host!, locale: AMP.config.locale)
        
        guard let path = filename.path else
        {
            return
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(path) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }

        filename = filename.URLByAppendingPathComponent(hash)
        data.writeToFile(path, atomically: true)
        
        // populate object with current data
        obj["url"]             = .JSONString(url)
        obj["host"]            = .JSONString(parsedURL.host!)
        obj["filename"]        = .JSONString(hash)
        obj["last_updated"]    = .JSONNumber(timestamp)

        if let checksum = checksum {
            let checksumParts = checksum.componentsSeparatedByString(":")
            if checksumParts.count > 1 {
                obj["checksum_method"] = .JSONString(checksumParts[0])
                obj["checksum"]        = .JSONString(checksumParts[1])
            }
        }
        
        // append to cache DB and save
        self.cacheDB!.append(JSONObject.JSONDictionary(obj))
    }
    
    /// Internal function to add an object to the cache DB
    ///
    /// - parameter request: request (used to extract URL)
    /// - parameter checksumMethod: the name of the used method used to create the `checksum`
    /// - parameter checksum: the checksum calculated by the `checksumMethod`
    internal class func saveToCache(request: NSURLRequest, checksumMethod: String, checksum: String) {
        // load cache DB if not loaded yet
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        
        // fetch current timestamp truncated to maximum resolution of 1 ms
        let timestamp = trunc(NSDate().timeIntervalSince1970 * 1000.0) / 1000.0
        
        // pop current cache DB entry
        var obj:[String:JSONObject] = self.getCacheDBEntry(request.URLString) ?? [:]
        self.removeCacheDBEntries(withURL: request.URLString)
        
        guard let requestURL = request.URL, requestHost = requestURL.host else {
            return
        }
        
        // populate object with current data
        obj["url"]             = .JSONString(request.URLString)
        obj["host"]            = .JSONString(requestHost)
        obj["filename"]        = .JSONString(request.URLString.cryptoHash(.MD5))
        obj["last_updated"]    = .JSONNumber(timestamp)
        obj["checksum_method"] = .JSONString(checksumMethod)
        obj["checksum"]        = .JSONString(checksum)
        
        // append to cache DB and save
        self.cacheDB!.append(JSONObject.JSONDictionary(obj))
        self.saveCacheDB()
    }

    // MARK: - Private API
    
    /// Private function to load cache DB from disk
    private class func loadCacheDB(locale: String = AMP.config.locale) {
        let fileURL = self.cacheFile("cacheIndex.json", locale: locale)
        do {
            // try loading from disk
            let jsonString = try String(contentsOfFile: fileURL.path!)
            
            // decode json object and set internal static variable
            let jsonObject = JSONDecoder(jsonString).jsonObject
            if case .JSONArray(let array) = jsonObject {
                self.cacheDB = array
            } else {
                // invalid json, reset the cache db and remove disk cache completely
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(self.cacheBaseDir(locale: locale).path!)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
                if AMP.config.loggingEnabled {
                    print("AMP: Could not load cache DB index, corrupt file")
                }
                self.cacheDB = []
            }
        } catch {
            // no index file, create empty cache db
            self.cacheDB = []
        }
    }
    
    /// Private function to save the cache DB to disk
    internal class func saveCacheDB(locale: String = AMP.config.locale) {
        // can not save nothing
        guard let cacheDB = self.cacheDB else {
            return
        }
        
        // create a valid JSON object and serialize
        let jsonObject = JSONObject.JSONArray(cacheDB)
        if let jsonString = JSONEncoder(jsonObject).prettyJSONString {
            do {
                let basePath = self.cacheBaseDir(locale: locale).path!
                let file = self.cacheFile("cacheIndex.json", locale: locale).path!
                
                // make sure the cache dir is there
                if !NSFileManager.defaultManager().fileExistsAtPath(basePath) {
                    try NSFileManager.defaultManager().createDirectoryAtPath(basePath, withIntermediateDirectories: true, attributes: nil)
                }

                // try saving to disk
                try jsonString.writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                // saving failed, remove disk cache completely because we don't have a clue what's in it
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(self.cacheBaseDir(locale: locale).path!)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
                if AMP.config.loggingEnabled {
                    print("AMP: Could not save cache DB index")
                }
            }
        }
    }
    
    
    /// Private function to remove entries with a specific url from the cache DB
    private class func removeCacheDBEntries(withURL urlString: String) {
        removeCacheDBEntries(forKey: "url", value: urlString)
    }
    
    
    /// Private function to remove entries from the cache DB
    private class func removeCacheDBEntries(forKey key: String, value: String) {
        self.cacheDB = self.cacheDB!.filter({ entry -> Bool in
            guard case .JSONDictionary(let dict) = entry where dict[key] != nil,
                case .JSONString(let entryValue) = dict[key]! where entryValue == value else {
                    return true
            }
            return false
        })
    }
    
    /// Internal function to return the base directory for the AMP cache
    ///
    /// - parameter host: the API host to fetch the cache dir for
    /// - parameter locale: the locale of the language that should be used
    /// - returns: File URL to the cache dir
    internal class func cacheBaseDir(host: String, locale: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(locale)/\(host)")
        return fileURL
    }

    private class func cacheBaseDir(locale locale: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(locale)")
        return fileURL
    }

    private class func cacheFile(filename: String, locale: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(locale)/\(filename)")
        return fileURL
    }

}