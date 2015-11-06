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

import Alamofire
import DEjson

// TODO: Export interface and make generic to use cache for other requests

/// Base Request class that handles caching
public class AMPRequest {
    private static var cacheDB:[JSONObject]?
    
    // MARK: - API

    /// Async fetch JSON from AMP Server
    ///
    /// - Parameter endpoint: the API endpoint to query
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func fetchJSON(endpoint: String, queryParameters: [String:String]?, cached: Bool, callback: (Result<JSONObject, AMPError> -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        let cacheName = self.cacheName(NSURL(string: urlString)!)

        let fromCache:(String -> Result<JSONObject, AMPError>) = { cacheName in
            // Check disk cache before running HTTP request
            if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
                // return from cache instantly
                do {
                    // fetch data from cache
                    let data = try String(contentsOfFile: cacheName)
                    var json = JSONDecoder(data).jsonObject
                    
                    // patch last_updated into response
                    json = self.augmentJSONWithChangeDate(json, urlString: urlString)
                    return .Success(json)
                } catch {
                    // do nothing, fallthrough to HTTP request
                }
            }
            return .Failure(AMPError.NoData)
        }
        
        if cached {
            let result = fromCache(cacheName)
            if case .Success(let json) = result {
                // call callback in correct queue
                dispatch_async(AMP.config.responseQueue) {
                    callback(.Success(json))
                }
                return
            }
        }
        
        var headers = self.headers()
        headers["Accept"] = "application/json"
        
        AMP.config.alamofire.request(.GET, urlString, headers:headers).responseDEJSON { response in
            // save response to cache
            self.saveToCache(response.request!, response.result)
            
            // object can only be saved if there is a request url and the status code of the response is a 200
            guard response.result.isSuccess else {
                // fallback to cache
                callback(fromCache(cacheName))
                return
            }

            // patch last_updated into response
            let patchedResult:Result<JSONObject, AMPError> = .Success(self.augmentJSONWithChangeDate(response.result.value!, urlString: urlString))
            // call callback in correct queue
            dispatch_async(AMP.config.responseQueue) {
                callback(patchedResult)
            }
        }
    }
    
    /// Async fetch a binary file from AMP Server
    ///
    /// - Parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    public class func fetchBinary(urlString: String, queryParameters: [String:String]?, cached: Bool, checksumMethod: String, checksum: String, callback: (Result<String, AMPError> -> Void)) {
        let headers = self.headers()
        let url = NSURL(string: urlString)!
        
        while true {
            // TODO: Make unittest
            
            // validate checksum
            let cacheDBEntry = self.getCacheDBEntry(urlString)
            guard (cacheDBEntry != nil) && (cacheDBEntry!["filename"] != nil) &&
                  (cacheDBEntry!["checksum_method"] != nil) && (cacheDBEntry!["checksum"] != nil),
                  case .JSONString(let filename)             = cacheDBEntry!["filename"]!,
                  case .JSONString(let cachedChecksumMethod) = cacheDBEntry!["checksum_method"]!,
                  case .JSONString(let cachedChecksum)       = cacheDBEntry!["checksum"]! else {
                break
            }

            let fileURL = self.cacheBaseDir(url.host!, locale: AMP.config.locale)
            let cacheName = fileURL.URLByAppendingPathComponent(filename).path!

            if (cachedChecksumMethod != checksumMethod) || (cachedChecksum != checksum) {
                // if checksum changed DO NOT USE cache
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(cacheName)
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                break
            }
            
            // Check disk cache
            if cached && NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
                // return from cache instantly
                dispatch_async(AMP.config.responseQueue) {
                    callback(.Success(cacheName))
                }
                return
            }
        }
        
        // destination block for Alamofire request
        let destination = { (file_url: NSURL, response: NSHTTPURLResponse) -> NSURL in
            return NSURL(fileURLWithPath: self.cacheName(url))
        }

        // Start download task
        let downloadTask = AMP.config.alamofire.download(.GET, urlString, parameters: queryParameters, encoding: .URLEncodedInURL, headers: headers, destination: destination).response { (request, response, data, error) -> Void in
            
            // check for download errors
            if error != nil {
                // remove file
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(self.cacheName(url))
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                // call callback in correct queue
                dispatch_async(AMP.config.responseQueue) {
                    callback(.Failure(AMPError.NoData))
                }
            } else {
                // no error, save file to cache db
                var ckSumMethod = checksumMethod
                var ckSum = checksum
                if ckSumMethod == "null" {
                    // update checksum if method was "null"
                    ckSumMethod = "sha256"
                    ckSum = self.cachedFile(urlString)!.cryptoHash(.SHA256).hexString()
                }
                self.saveToCache(request!, checksumMethod: ckSumMethod, checksum: ckSum)
                
                // call callback in correct queue
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Success(self.cacheName(url)))
                }
            }
        }
        
        // Register the download with the global progress handler
        AMP.registerProgress(downloadTask.progress, urlString: urlString)
    }
    
    /// Fetch a file from the cache or return nil
    ///
    /// - Parameter urlString: url of the file to fetch from cache
    /// - Returns: NSData with memory mapped file or nil if not in cache
    public class func cachedFile(urlString:String) -> NSData? {
        let url = NSURL(string: urlString)!
        let cacheName = self.cacheName(url)

        var data:NSData? = nil
        if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
            do {
                data = try NSData(contentsOfFile: cacheName, options: NSDataReadingOptions.DataReadingMappedIfSafe)
            } catch {
                // file could not be loaded, do nothing
            }
        }
        return data
    }
    
    /// Async POST JSON to AMP Server
    ///
    /// - Parameter endpoint: the API endpoint to post to
    /// - Parameter queryParameters: any get parameters to include in the query or nil
    /// - Parameter body: dictionary with parameters (will be JSON encoded)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func postJSON(endpoint: String, queryParameters: [String:String]?, body: [String:AnyObject], callback: (Result<JSONObject, AMPError> -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        var headers = self.headers()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        
        AMP.config.alamofire.request(.POST, urlString, parameters: body, encoding: .JSON, headers: headers).responseDEJSON { response in
            // call callback in correct queue
            dispatch_async(AMP.config.responseQueue) {
                callback(response.result)
            }
        }
    }
    
    // MARK: - Private
    
    /// Build url from partial API endpoint
    ///
    /// - Parameter endpoint: the API endpoint
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Returns: complete valid URL string for query based on `AMP.config`
    private class func buildURL(endpoint: String, queryParameters: [String:String]?) -> String {
        // append endpoint to base url
        let url = AMP.config.serverURL.URLByAppendingPathComponent(endpoint)
        
        // add query parameters
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [NSURLQueryItem]()
        if let parameters = queryParameters {
            for (key, value) in parameters {
                components.queryItems!.append(NSURLQueryItem(name: key, value: value))
            }
        }
        
        // return canonical url
        let urlString = components.URLString
        return urlString
    }
    
    /// Prepare headers for request
    ///
    /// - Returns: Headers-Dictionary for use in Alamofire request
    private class func headers() -> [String:String] {
        var headers = [String:String]()
        if let token = AMP.config.sessionToken {
            headers["Authorization"] = "Token " + token
        }
        return headers
    }

    /// Inject `last_updated` into json response
    ///
    /// - Parameter json: the JSON object to patch
    /// - Parameter urlString: the request URL (used to find the last update date in cache DB)
    /// - Returns: new JSON object with added `last_updated` field if input was a dictionary, does not change arrays
    private class func augmentJSONWithChangeDate(json: JSONObject, urlString: String) -> JSONObject {
        // augment json with timestamp for last update
        guard case .JSONDictionary(var dict) = json,
              let cacheDBEntry = self.getCacheDBEntry(urlString) where cacheDBEntry["last_updated"] != nil,
              case .JSONNumber = cacheDBEntry["last_updated"]! else {
                // return unchanged input if it neither was not a dictionary or there is no entry in cache DB
                return json
        }
        
        dict["last_updated"] = cacheDBEntry["last_updated"]
        return .JSONDictionary(dict)
    }
    
    // Make init private to avoid instanciating as all functions are class functions
    private init() {
        
    }
}