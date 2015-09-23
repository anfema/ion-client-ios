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
// TODO: Cache DB with url->file mapping

public class AMPRequest {
    private static var cacheDB:Array<JSONObject>?
    
    // MARK: Private
    private class func buildURL(endpoint: String, queryParameters:Dictionary<String, String>?) -> String {
        let url = AMP.config.serverURL.URLByAppendingPathComponent(endpoint)
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        components.queryItems = Array<NSURLQueryItem>()
        if let parameters = queryParameters {
            for (key, value) in parameters {
                components.queryItems!.append(NSURLQueryItem(name: key, value: value))
            }
        }
        let urlString = components.URLString
        return urlString
    }
    
    private class func headers() -> Dictionary<String, String> {
        let headers = [
            // TODO: Make login dynamic, use login API
            "Authorization": "Basic YWRtaW46dGVzdA==",
        ]
        return headers
    }

    private class func loadCacheDB() {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/cacheIndex.json")

        do {
            let jsonString = try String(contentsOfFile: fileURL.path!)
            let jsonObject = JSONDecoder(jsonString).jsonObject
            if case .JSONArray(let array) = jsonObject {
                self.cacheDB = array
            } else {
                print("AMP: Could not load cache DB index, corrupt file")
                self.cacheDB = Array<JSONObject>()
            }
        } catch {
            // no index file, create empty cache db
            self.cacheDB = Array<JSONObject>()
        }
    }
    
    private class func saveCacheDB() {
        guard let cacheDB = self.cacheDB else {
            return
        }
        let jsonObject = JSONObject.JSONArray(cacheDB)
        if let jsonString = JSONEncoder(jsonObject).prettyJSONString {
            do {
                let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
                let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/cacheIndex.json")
                try jsonString.writeToFile(fileURL.path!, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                print("AMP: Could not save cache DB index")
            }
        }
    }
    
    private class func cacheName(url: NSURL) -> String {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        var fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(url.host!)")
        if !NSFileManager.defaultManager().fileExistsAtPath(fileURL.path!) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(fileURL.path!, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("AMP: Could not create cache dir!")
            }
        }
        fileURL = fileURL.URLByAppendingPathComponent(url.URLString.md5())
        return fileURL.path!
    }
    
    private class func saveToCache(optRequest: NSURLRequest?, _ optResponse: NSHTTPURLResponse?, _ result:Result<JSONObject>) {
        guard let request = optRequest,
              let response = optResponse where response.statusCode == 200,
              case .Success(let data) = result,
              let json = JSONEncoder(data).prettyJSONString else {
            return
        }

        do {
            let cacheName = self.cacheName(request.URL!)
            try json.writeToFile(cacheName, atomically: true, encoding: NSUTF8StringEncoding)
            self.saveToCache(request, response)
        } catch {
            // do nothing, could not be saved to cache -> nonfatal
        }
    }
    
    private class func saveToCache(request: NSURLRequest?, _ response: NSHTTPURLResponse?) {
        guard let request = request,
            let response = response where response.statusCode == 200 else {
                return
        }
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        let timestamp = trunc(NSDate().timeIntervalSince1970 * 1000.0) / 1000.0
        
        var obj:Dictionary<String, JSONObject>? = self.getCacheDBEntry(request.URLString)
        self.removeCacheDBEntry(request.URLString)

        if obj == nil {
            obj = Dictionary<String, JSONObject>()
        }
        obj!["url"]          = .JSONString(request.URLString)
        obj!["host"]         = .JSONString(request.URL!.host!)
        obj!["filename"]     = .JSONString(request.URLString.md5())
        obj!["last_updated"] = .JSONNumber(timestamp)

        self.cacheDB!.append(JSONObject.JSONDictionary(obj!))

        self.saveCacheDB()
    }
    
    private class func getCacheDBEntry(urlString: String) -> Dictionary<String, JSONObject>? {
        if self.cacheDB == nil {
            self.loadCacheDB()
        }
        for entry in self.cacheDB! {
            guard case .JSONDictionary(let dict) = entry where dict["url"] != nil,
                  case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                    continue
            }
            return dict
        }
        return nil
    }

    private class func removeCacheDBEntry(urlString: String) {
        self.cacheDB = self.cacheDB!.filter({ entry -> Bool in
            guard case .JSONDictionary(let dict) = entry where dict["url"] != nil,
                  case .JSONString(let entryURL) = dict["url"]! where entryURL == urlString else {
                    return true
            }
            return false
        })
    }
    
    private class func augmentJSONWithChangeDate(json: JSONObject, urlString: String) -> JSONObject {
        // augment json with timestamp for last update
        guard case .JSONDictionary(var dict) = json,
              let cacheDBEntry = self.getCacheDBEntry(urlString) where cacheDBEntry["last_updated"] != nil,
              case .JSONNumber = cacheDBEntry["last_updated"]! else {
                return json
        }
        
        dict["last_updated"] = cacheDBEntry["last_updated"]
        return .JSONDictionary(dict)
    }
    
    // MARK: init
    private init() {
        
    }
    
    // MARK: API
    public class func fetchJSON(endpoint: String, queryParameters: Dictionary<String,String>?, cached: Bool, callback: (Result<JSONObject> -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        let cacheName = self.cacheName(NSURL(string: urlString)!)

        if cached {
            // Check disk cache before running HTTP request
            if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
                // return from cache instantly
                do {
                    let data = try String(contentsOfFile: cacheName)
                    var json = JSONDecoder(data).jsonObject
                    json = self.augmentJSONWithChangeDate(json, urlString: urlString)
                    dispatch_async(AMP.config.responseQueue) {
                        callback(.Success(json))
                    }
                    return
                } catch {
                    // do nothing, fallthrough to HTTP request
                }
            }
        }
        
        var headers = self.headers()
        headers["Accept"] = "application/json"

        Alamofire.request(.GET, urlString, headers:headers).responseDEJSON { (request, response, result) in
            self.saveToCache(request, response, result)
            var patchedResult = result
            if case .Success(let json) = result {
                patchedResult = .Success(self.augmentJSONWithChangeDate(json, urlString: urlString))
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(patchedResult)
            }
        }
    }

    public class func fetchJSON(endpoint: String, queryParameters: Dictionary<String,String>?, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }
    
    public class func fetchJSONUncached(endpoint: String, queryParameters: Dictionary<String,String>?, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }
    
    // returns file name on disk in callback
    public class func fetchBinary(urlString: String, queryParameters: Dictionary<String, String>?, cached:Bool, callback: (Result<String> -> Void)) {
        let headers = self.headers()
        let cacheName = self.cacheName(NSURL(string: urlString)!)
        
        let destination = { (url: NSURL, response: NSHTTPURLResponse) -> NSURL in
            return NSURL(fileURLWithPath: cacheName)
        }
        
        // Check disk cache
        if cached && NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
            // return from cache instantly
            dispatch_async(AMP.config.responseQueue) {
                callback(Result.Success(cacheName))
            }
            return
        }
        
        let downloadTask = Alamofire.download(.GET, urlString, parameters: queryParameters, encoding: .URLEncodedInURL, headers: headers, destination: destination).response { (request, response, data, error) -> Void in
            if let err = error {
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Failure(data, err))
                }
            } else {
                self.saveToCache(request, response)
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Success(cacheName))
                }
            }
        }
        
        AMP.registerProgress(downloadTask.progress, urlString: urlString)
    }
    
    public class func fetchBinary(endpoint: String, queryParameters: Dictionary<String,String>?, callback: (Result<String> -> Void)) {
        self.fetchBinary(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }
    
    public class func fetchBinaryUncached(endpoint: String, queryParameters: Dictionary<String,String>?, callback: (Result<String> -> Void)) {
        self.fetchBinary(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }
    
    public class func resetCache(host: String) {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/\(host)")
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

}