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
    
    private class func buildURL(endpoint: String, queryParameters:Dictionary<String, String>) -> String {
        let url = AMP.config.serverURL.URLByAppendingPathComponent(endpoint)
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        components.queryItems = Array<NSURLQueryItem>()
        for (key, value) in queryParameters {
            components.queryItems!.append(NSURLQueryItem(name: key, value: value))
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
    
    private init() {
        
    }
    
    public class func fetchJSON(endpoint: String, queryParameters: Dictionary<String,String>, cached: Bool, callback: (Result<JSONObject> -> Void)) {
        let urlString = self.buildURL(endpoint, queryParameters: queryParameters)
        let cacheName = self.cacheName(NSURL(string: urlString)!) + ".json"

        if cached {
            // Check disk cache before running HTTP request
            if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
                // return from cache instantly
                do {
                    let data = try String(contentsOfFile: cacheName)
                    let json = JSONDecoder(data).jsonObject
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
            if case .Success(let data) = result {
                if response!.statusCode == 200 {
                    if let json = JSONEncoder(data).prettyJSONString {
                        do {
                            try json.writeToFile(cacheName, atomically: true, encoding: NSUTF8StringEncoding)
                        } catch {
                            // do nothing, could not be saved to cache -> nonfatal
                        }
                    }
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(result)
            }
        }
    }

    public class func fetchJSON(endpoint: String, queryParameters: Dictionary<String,String>, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }
    
    public class func fetchJSONUncached(endpoint: String, queryParameters: Dictionary<String,String>, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }
    
    // returns file name on disk in callback
    public class func fetchBinary(urlString: String, queryParameters: Dictionary<String, String>, cached:Bool, callback: (Result<String> -> Void)) {
        let headers = self.headers()
        let cacheName = self.cacheName(NSURL(string: urlString)!)
        
        let destination = { (url: NSURL, response: NSHTTPURLResponse) -> NSURL in
            return NSURL(string: cacheName)!
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
                dispatch_async(AMP.config.responseQueue) {
                    callback(Result.Success(cacheName))
                }
            }
        }
        
        AMP.registerProgress(downloadTask.progress, urlString: urlString)
    }
    
    public class func fetchBinary(endpoint: String, queryParameters: Dictionary<String,String>, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: true, callback: callback)
    }
    
    public class func fetchBinaryUncached(endpoint: String, queryParameters: Dictionary<String,String>, callback: (Result<JSONObject> -> Void)) {
        self.fetchJSON(endpoint, queryParameters: queryParameters, cached: false, callback: callback)
    }

}