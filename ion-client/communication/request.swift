//
//  request.swift
//  ion-client
//
//  Created by Johannes Schriewer on 22.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

import HashExtensions
import DEjson
import iso_rfc822_date


// TODO: Export interface and make generic to use cache for other requests

/// Caching behaviour
public enum IONCacheBehaviour {
    
    /// Prefer cache over request
    case Prefer
    
    /// Force cached content, error if not cached
    case Force
    
    /// Ignore cached content, force a request
    case Ignore
}

internal extension NSData {
    func hexString() -> String {
        var bytes = [UInt8](count: self.length, repeatedValue: 0)
        self.getBytes(&bytes, length:self.length)
        
        let convert_table = "0123456789abcdef"
        var s = ""
        for byte in bytes {
            s.append(convert_table.characters[convert_table.startIndex.advancedBy(Int(byte >> 4))])
            s.append(convert_table.characters[convert_table.startIndex.advancedBy(Int(byte & 0x0f))])
        }
        return s
    }
}


/// Base Request class that handles caching
public class IONRequest {
    static var cacheDB:[JSONObject]?
    
    // MARK: - API

    /// Async fetch JSON from ION Server
    ///
    /// - parameter endpoint: the API endpoint to query
    /// - parameter queryParameters: any query parameters to include in the query or nil
    /// - parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`
    public class func fetchJSON(endpoint: String, queryParameters: [String:String]?, cached: IONCacheBehaviour, callback: (Result<JSONObject, IONError> -> NSDate?)) {
        guard let urlString = self.buildURL(endpoint, queryParameters: queryParameters),
              let url = NSURL(string: urlString),
              let cacheName = self.cacheName(url),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        let fromCache:(String -> Result<JSONObject, IONError>) = { cacheName in
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
            return .Failure(.NoData(nil))
        }
        
        if cached == .Prefer || cached == .Force {
            let result = fromCache(cacheName)
            if case .Success(let json) = result {
                // call callback in correct queue
                responseQueueCallback(callback, parameter: .Success(json))
                return
            } else if cached == .Force {
                responseQueueCallback(callback, parameter: .Failure(.ServerUnreachable))
                return
            }
        }
        
        var headers = self.headers()
        headers["Accept"] = "application/json"
        if let index = self.getCacheDBEntry(urlString) {
            if let rawLastUpdated = index["last_updated"],
               case .JSONNumber(let timestamp) = rawLastUpdated {
                let lastUpdated = NSDate(timeIntervalSince1970: NSTimeInterval(timestamp))
                headers["If-Modified-Since"] = lastUpdated.rfc822DateString()
            }
        }
        
        let request = alamofire.request(.GET, urlString, headers:headers)
        
        request.responseDEJSON { response in
            if case .Failure(let error) = response.result {
                if case .NotAuthorized = error {
                    responseQueueCallback(callback, parameter: .Failure(error))
                } else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                }
                
                return
            }
            
            guard let request = response.request else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            // save response to cache
            self.saveToCache(request, ion_client.Result(result: response.result))
            
            // object can only be saved if there is a request url and the status code of the response is a 200
            var jsonObject: JSONObject? = nil
            if response.result.isSuccess,
               let jsonResponse = response.result.value,
               let json = jsonResponse.json {
                jsonObject = json
            } else {
                // fallback to cache
                if case .Success(let json) = fromCache(cacheName) {
                    jsonObject = json
                }
            }
            
            if let jsonObject = jsonObject {
                // patch last_updated into response
                let patchedResult:Result<JSONObject, IONError> = .Success(self.augmentJSONWithChangeDate(jsonObject, urlString: urlString))
                // call callback in correct queue
                dispatch_async(ION.config.responseQueue) {
                    if let date = callback(patchedResult) {
                        self.saveToCache(request, checksumMethod: "null", checksum: "", lastUpdate: date)
                    }
                }
            } else {
                responseQueueCallback(callback, parameter: .Failure(.NoData(nil)))
            }
        }
        
        request.resume()
    }
    
    /// Async fetch a binary file from ION Server
    ///
    /// - parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - parameter queryParameters: any query parameters to include in the query or nil
    /// - parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    public class func fetchBinary(urlString: String, queryParameters: [String:String]?, cached: IONCacheBehaviour, checksumMethod: String, checksum: String, callback: (Result<String, IONError> -> Void)) {
        let headers = self.headers()
        guard let url = NSURL(string: urlString),
              let cacheName = self.cacheName(url),
              let alamofire = ION.config.alamofire else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
        }
        
        if cached == .Force || cached == .Prefer {
            let cacheResult = self.fetchFromCache(urlString, checksumMethod: checksumMethod, checksum: checksum)
            if case .Success = cacheResult {
                responseQueueCallback(callback, parameter: cacheResult)
                return
            } else if cached == .Force {
                responseQueueCallback(callback, parameter: .Failure(.ServerUnreachable))
                return
            }
        }
        
        // destination block for Alamofire request
        let destination = { (file_url: NSURL, response: NSHTTPURLResponse) -> NSURL in
            return NSURL(fileURLWithPath: cacheName + ".tmp")
        }

        // Start download task
        let downloadTask = alamofire.download(
            .GET, urlString,
            parameters: queryParameters,
            encoding: .URLEncodedInURL,
            headers: headers,
            destination: destination)
        
        downloadTask.progress { (bytesRead, totalBytesRead, totalBytesExpectedToRead) -> Void in
            // Register the download with the global progress handler
            if totalBytesExpectedToRead < 0 {
                // server sent no content-length header, we expect one byte more than we got
                ION.registerProgress(totalBytesRead, bytesExpected: totalBytesRead + 1, urlString: urlString)
            } else {
                // server sent a content-length header, trust it
                ION.registerProgress(totalBytesRead, bytesExpected: totalBytesExpectedToRead, urlString: urlString)
            }
        }
        
        downloadTask.response { (request, response, data, error) -> Void in
            // check for download errors
            if error != nil || response?.statusCode != 200 {
                // TODO: Request bogus binary to test error case
                
                // remove temp file
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(cacheName + ".tmp")
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                
                guard let response = response else {
                    responseQueueCallback(callback, parameter: .Failure(.ServerUnreachable))
                    return
                }

                if response.statusCode == 401 || response.statusCode == 403 {
                    responseQueueCallback(callback, parameter: .Failure(.NotAuthorized))
                    return
                }

                // call final update for progress, we're using 1 here because the user likely wants to
                // calculate a percentage and thus divides those numbers
                if response.allHeaderFields["Content-Length"] == nil {
                    ION.registerProgress(1, bytesExpected: 1, urlString: urlString)
                }

                // try falling back to cache
                dispatch_async(ION.config.responseQueue) {
                    let result = fetchFromCache(urlString, checksumMethod: checksumMethod, checksum: checksum)
                    if case .Failure = result {
                        if response.statusCode == 304 {
                            callback(.Success(""))
                            return
                        }
                    }
                    callback(result)
                }
            } else {
                // move temp file
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(cacheName)
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                do {
                    try NSFileManager.defaultManager().moveItemAtPath(cacheName + ".tmp", toPath: cacheName)
                } catch {
                    // ok moving failed
                    responseQueueCallback(callback, parameter: .Failure(.NoData(error)))
                    return
                }
                
                guard let request = request else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
                }
                
                // no error, save file to cache db
                var ckSumMethod = checksumMethod
                var ckSum = checksum
                if ckSumMethod == "null" {
                    // update checksum if method was "null"
                    if let cachedFileData = self.cachedFile(urlString) {
                        ckSumMethod = "sha256"
                        ckSum = cachedFileData.cryptoHash(.SHA256).hexString()
                    } else {
                        // TODO: return error or do nothing when checksum could not be updated?
                    }
                }
                
                // finish up progress reporting
                if let unwrapped = response where unwrapped.allHeaderFields["Content-Length"] == nil,
                   let cachedFileData = self.cachedFile(urlString) {
                    let bytes: Int64 = Int64(cachedFileData.length)
                    ION.registerProgress(bytes, bytesExpected: bytes, urlString: urlString)
                }

                self.saveToCache(request, checksumMethod: ckSumMethod, checksum: ckSum)
                
                // call callback in correct queue
                responseQueueCallback(callback, parameter: .Success(cacheName))
            }
        }
        
        downloadTask.resume()
    }
    
    /// Fetch a file from the cache or return nil
    ///
    /// - parameter urlString: url of the file to fetch from cache
    /// - returns: `NSData` with memory mapped file or `nil` if not in cache
    public class func cachedFile(urlString:String) -> NSData? {
        guard let url = NSURL(string: urlString),
              let cacheName = self.cacheName(url) else {
            return nil
        }

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
    
    /// Async POST JSON to ION Server
    ///
    /// - parameter endpoint: the API endpoint to post to
    /// - parameter queryParameters: any get parameters to include in the query or nil
    /// - parameter body: dictionary with parameters (will be JSON encoded)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`
    public class func postJSON(endpoint: String, queryParameters: [String:String]?, body: [String:AnyObject], callback: (Result<JSONResponse, IONError> -> Void)) {
        guard let urlString = self.buildURL(endpoint, queryParameters: queryParameters),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        var headers = self.headers()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"
        
        let request = alamofire.request(.POST, urlString, parameters: body, encoding: .JSON, headers: headers)
        request.responseDEJSON { response in
            // call callback in correct queue
            responseQueueCallback(callback, parameter: ion_client.Result(result: response.result))
        }
        request.resume()
    }
    
    // MARK: - Private
    
    /// Build url from partial API endpoint
    ///
    /// - parameter endpoint: the API endpoint
    /// - parameter queryParameters: any query parameters to include in the query or nil
    /// - returns: complete valid URL string for query based on `ION.config`
    private class func buildURL(endpoint: String, queryParameters: [String:String]?) -> String? {
        guard let serverURL = ION.config.serverURL else {
            return nil
        }
        
        // append endpoint to base url
        let url = serverURL.URLByAppendingPathComponent(endpoint)
        
        // add query parameters
        guard let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        
        var queryItems: [NSURLQueryItem] = []
        
        if let parameters = queryParameters {
            for (key, value) in parameters {
                queryItems.append(NSURLQueryItem(name: key, value: value))
            }
        }
        
        components.queryItems = queryItems
        
        // return canonical url
        let urlString = components.URLString
        return urlString
    }
    
    /// Prepare headers for request
    ///
    /// - returns: Headers-Dictionary for use in Alamofire request
    private class func headers() -> [String:String] {
        var headers = ION.config.additionalHeaders
        
        if let token = ION.config.sessionToken {
            headers["Authorization"] = "Token " + token
        }
        
        return headers
    }

    /// Inject `last_updated` into json response
    ///
    /// - parameter json: the JSON object to patch
    /// - parameter urlString: the request URL (used to find the last update date in cache DB)
    /// - returns: new JSON object with added `last_updated` field if input was a dictionary, does not change arrays
    private class func augmentJSONWithChangeDate(json: JSONObject, urlString: String) -> JSONObject {
        // augment json with timestamp for last update
        guard case .JSONDictionary(var dict) = json,
              let cacheDBEntry = self.getCacheDBEntry(urlString),
              let rawLastUpdated = cacheDBEntry["last_updated"],
              case .JSONNumber = rawLastUpdated else {
                // return unchanged input if it neither was not a dictionary or there is no entry in cache DB
                return json
        }
        
        dict["last_updated"] = cacheDBEntry["last_updated"]
        return .JSONDictionary(dict)
    }
    
    /// Load file from cache
    ///
    /// - parameter urlString: URL of file
    /// - parameter checksumMethod: used checksumming method
    /// - parameter checksum: checksum to compare to
    /// - returns: Success with cached file name or Failure
    internal class func fetchFromCache(urlString: String, checksumMethod: String, checksum: String) -> Result<String, IONError> {
        
        guard let url = NSURL(string: urlString), host = url.host else {
            return .Failure(.DidFail)
        }

        // validate checksum
        guard let cacheDBEntry = self.getCacheDBEntry(urlString) else {
            return .Failure(.InvalidJSON(nil))
        }
        
        guard let rawFileName = cacheDBEntry["filename"],
            rawChecksumMethod = cacheDBEntry["checksum_method"],
            rawChecksum = cacheDBEntry["checksum"],
            case .JSONString(let filename)             = rawFileName,
            case .JSONString(let cachedChecksumMethod) = rawChecksumMethod,
            case .JSONString(let cachedChecksum)       = rawChecksum else {
                return .Failure(.InvalidJSON(nil))
        }
        
        let fileURL = self.cacheBaseDir(host, locale: ION.config.locale)
        
        guard let cacheName = fileURL.URLByAppendingPathComponent(filename).path else {
            return .Failure(.DidFail)
        }
        
        // ios 8.4 inserts spaces into our checksums, so remove them again
        if (cachedChecksumMethod != checksumMethod) || (cachedChecksum.stringByReplacingOccurrencesOfString(" ", withString: "") != checksum.stringByReplacingOccurrencesOfString(" ", withString: "")) {
            if checksumMethod != "null" {
                // if checksum changed DO NOT USE cache
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(cacheName)
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                return .Failure(.NoData(nil))
            }
        }
        
        // Check disk cache
        if NSFileManager.defaultManager().fileExistsAtPath(cacheName) {
            return .Success(cacheName)
        } else {
            return .Failure(.NoData(nil))
        }
    }

    
    // Make init private to avoid instanciating as all functions are class functions
    private init() {}
}