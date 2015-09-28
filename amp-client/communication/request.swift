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

public class AMPRequest {
    private static var cacheDB:[JSONObject]?
    
    // MARK: - API

    /// Async fetch JSON from AMP Server
    ///
    /// - Parameter endpoint: the API endpoint to query
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func fetchJSON(endpoint: String, queryParameters: [String:String]?, cached: Bool, callback: (Result<JSONObject> -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        let cacheName = self.cacheName(NSURL(string: urlString)!)
        
        if cached {
            // Check disk cache before running HTTP request
            if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
                // return from cache instantly
                do {
                    // fetch data from cache
                    let data = try String(contentsOfFile: cacheName)
                    var json = JSONDecoder(data).jsonObject
                    
                    // patch last_updated into response
                    json = self.augmentJSONWithChangeDate(json, urlString: urlString)
                    
                    // call callback in correct queue
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
        
        AMP.config.alamofire.request(.GET, urlString, headers:headers).responseDEJSON { (request, response, result) in
            // save response to cache
            self.saveToCache(request, response, result)
            
            // patch last_updated into response
            var patchedResult = result
            if case .Success(let json) = result {
                patchedResult = .Success(self.augmentJSONWithChangeDate(json, urlString: urlString))
            }
            
            // call callback in correct queue
            dispatch_async(AMP.config.responseQueue) {
                callback(patchedResult)
            }
        }
    }
    
    /// Async fetch cached JSON from AMP Server
    ///
    /// - Parameter endpoint: the API endpoint to query
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func fetchJSON(endpoint: String, queryParameters: [String:String]?, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }

    /// Async fetch JSON from AMP Server circumventing cache
    ///
    /// - Parameter endpoint: the API endpoint to query
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func fetchJSONUncached(endpoint: String, queryParameters: [String:String]?, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }
    
    /// Async fetch a binary file from AMP Server
    ///
    /// - Parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    public class func fetchBinary(urlString: String, queryParameters: [String:String]?, cached:Bool, callback: (Result<String> -> Void)) {
        let headers = self.headers()
        let cacheName = self.cacheName(NSURL(string: urlString)!)
        
        // destination block for Alamofire request
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
        
        // Start download task
        let downloadTask = AMP.config.alamofire.download(.GET, urlString, parameters: queryParameters, encoding: .URLEncodedInURL, headers: headers, destination: destination).response { (request, response, data, error) -> Void in
            
            // check for download errors
            if let err = error {
                // call callback in correct queue
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Failure(data, err))
                }
            } else {
                // no error, save file to cache db
                self.saveToCache(request, response)
                
                // call callback in correct queue
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Success(cacheName))
                }
            }
        }
        
        // Register the download with the global progress handler
        AMP.registerProgress(downloadTask.progress, urlString: urlString)
    }
    
    /// Async fetch a binary file from AMP Server (using cache if possible)
    ///
    /// - Parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    public class func fetchBinary(endpoint: String, queryParameters: [String:String]?, callback: (Result<String> -> Void)) {
        self.fetchBinary(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }

    /// Async fetch a binary file from AMP Server circumventing cache
    ///
    /// - Parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - Parameter queryParameters: any query parameters to include in the query or nil
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    public class func fetchBinaryUncached(endpoint: String, queryParameters: [String:String]?, callback: (Result<String> -> Void)) {
        self.fetchBinary(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }
    
    /// Async POST JSON to AMP Server
    ///
    /// - Parameter endpoint: the API endpoint to post to
    /// - Parameter queryParameters: any get parameters to include in the query or nil
    /// - Parameter body: dictionary with parameters (will be JSON encoded)
    /// - Parameter callback: a block to call when the request finishes, will be called in `AMP.config.responseQueue`
    public class func postJSON(endpoint: String, queryParameters: [String:String]?, body: [String:AnyObject], callback: ((NSHTTPURLResponse?, Result<JSONObject>) -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        var headers = self.headers()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        
        AMP.config.alamofire.request(.POST, urlString, parameters: body, encoding: .JSON, headers: headers).responseDEJSON { (request, response, result) in
            // call callback in correct queue
            dispatch_async(AMP.config.responseQueue) {
                callback(response, result)
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