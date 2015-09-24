//
//  request.swift
//  amp-client
//
//  Created by Johannes Schriewer on 22.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

import Alamofire
import DEjson

// TODO: Cache invalidation

extension AMPRequest {
    private static var cacheDB:[JSONObject]?
    
    // MARK: - external API
    
    /// Reset the complete AMP cache for a specific host
    ///
    /// - Parameter host: host to clear cache for
    public class func resetCache(host: String) {
        // remove complete cache dir for this host
        let fileURL = self.cacheBaseDir(host)
        do {
            try NSFileManager.defaultManager().removeItemAtPath(fileURL.path!)
        } catch {
            // non-fatal, could not remove item at path, so probably path did not exist
        }
        
        // remove all entries for this host from cache db
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        self.cacheDB = self.cacheDB!.filter({ entry -> Bool in
            guard case .JSONDictionary(let dict) = entry where dict["host"] != nil,
                case .JSONString(let entryHost) = dict["host"]! where entryHost == host else {
                    return true
            }
            return false
        })
        self.saveCacheDB()
    }
    
    // MARK: - Internal API
    
    /// Internal function to fetch the cache path for a specific URL
    ///
    /// - Parameter url: the URL to find in the cache
    /// - Returns: Path to the cache file (may not exist)
    internal class func cacheName(url: NSURL) -> String {
        var fileURL = self.cacheBaseDir(url.host!)
        
        // try to create the path if it does not exist
        if !NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(fileURL.path!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("AMP: Could not create cache dir!")
            }
        }
        
        // generate cache path
        fileURL = fileURL.URLByAppendingPathComponent(url.URLString.md5())
        return fileURL.path!
    }

    /// Internal function to fetch a cache DB entry
    ///
    /// - Parameter urlString: the URL to find in the cache DB
    /// - Returns: cache db entry (JSON dictionary unpacked into dictionary)
    internal class func getCacheDBEntry(urlString: String) -> [String:JSONObject]? {
        // load db if not already loaded
        if self.cacheDB == nil {
            self.loadCacheDB()
        }

        // find entry in cache db
        for case .JSONDictionary(let dict) in self.cacheDB! {
            guard dict["url"] != nil,
                  case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                continue
            }
            return dict
        }
        
        // nothing found
        return nil
    }

    /// Internal function to save a JSON response to the cache
    ///
    /// - Parameter optRequest: optional request (used for request url)
    /// - Parameter optResponse: optional response, checked for status code 200
    /// - Parameter result: the object to save
    internal class func saveToCache(optRequest: NSURLRequest?, _ optResponse: NSHTTPURLResponse?, _ result:Result<JSONObject>) {

        // object can only be saved if there is a request url and the status code of the response is a 200
        guard let request = optRequest,
            let response = optResponse where response.statusCode == 200,
            case .Success(let data) = result,
            let json = JSONEncoder(data).prettyJSONString else {
                return
        }
        
        do {
            // save objext to disk
            let cacheName = self.cacheName(request.URL!)
            try json.writeToFile(cacheName, atomically: true, encoding: NSUTF8StringEncoding)
            
            // save object to cache DB
            self.saveToCache(request, response)
        } catch {
            // do nothing, could not be saved to cache -> nonfatal
        }
    }
    
    /// Internal function to add an object to the cache DB
    ///
    /// - Parameter request: optional request (used to extract URL)
    /// - Parameter response: optional response, checked for status code
    internal class func saveToCache(request: NSURLRequest?, _ response: NSHTTPURLResponse?) {
        
        // object can only saved to cache DB if response was 200 and we have a request
        guard let request = request,
            let response = response where response.statusCode == 200 else {
                return
        }
        
        // load cache DB if not loaded yet
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        
        // fetch current timestamp truncated to maximum resolution of 1 ms
        let timestamp = trunc(NSDate().timeIntervalSince1970 * 1000.0) / 1000.0
        
        // pop current cache DB entry
        var obj:[String:JSONObject]? = self.getCacheDBEntry(request.URLString)
        self.removeCacheDBEntry(request.URLString)
        
        // if there was nothing to pop, create new object
        if obj == nil {
            obj = [String:JSONObject]()
        }
        
        // populate object with current data
        obj!["url"]          = .JSONString(request.URLString)
        obj!["host"]         = .JSONString(request.URL!.host!)
        obj!["filename"]     = .JSONString(request.URLString.md5())
        obj!["last_updated"] = .JSONNumber(timestamp)
        
        // append to cache DB and save
        self.cacheDB!.append(JSONObject.JSONDictionary(obj!))
        self.saveCacheDB()
    }

    // MARK: - Private API
    
    /// Private function to load cache DB from disk
    private class func loadCacheDB() {
        let fileURL = self.cacheBaseDir("cacheIndex.json")
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
                    try NSFileManager.defaultManager().removeItemAtPath(self.cacheBaseDir("").path!)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
                print("AMP: Could not load cache DB index, corrupt file")
                self.cacheDB = [JSONObject]()
            }
        } catch {
            // no index file, create empty cache db
            self.cacheDB = [JSONObject]()
        }
    }
    
    /// Private function to save the cache DB to disk
    private class func saveCacheDB() {
        // can not save nothing
        guard let cacheDB = self.cacheDB else {
            return
        }
        
        // create a valid JSON object and serialize
        let jsonObject = JSONObject.JSONArray(cacheDB)
        if let jsonString = JSONEncoder(jsonObject).prettyJSONString {
            do {
                let basePath = self.cacheBaseDir("").path!
                let file = self.cacheBaseDir("cacheIndex.json").path!
                
                // make sure the cache dir is there
                if !NSFileManager.defaultManager().fileExistsAtPath(basePath) {
                    try NSFileManager.defaultManager().createDirectoryAtPath(basePath, withIntermediateDirectories: true, attributes: nil)
                }

                // try saving to disk
                try jsonString.writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                // saving failed, remove disk cache completely because we don't have a clue what's in it
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(self.cacheBaseDir("").path!)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
                print("AMP: Could not save cache DB index")
            }
        }
    }
    
    /// Private function to remove an entry from the cache DB
    private class func removeCacheDBEntry(urlString: String) {
        self.cacheDB = self.cacheDB!.filter({ entry -> Bool in
            guard case .JSONDictionary(let dict) = entry where dict["url"] != nil,
                case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                    return true
            }
            return false
        })
    }
    
    /// Private function to return the base directory for the AMP cache
    ///
    /// - Parameter host: the API host to fetch the cache dir for
    /// - Returns: File URL to the cache dir
    private class func cacheBaseDir(host: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(host)")
        return fileURL
    }
}