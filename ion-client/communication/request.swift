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
    case prefer

    /// Force cached content, error if not cached
    case force

    /// Ignore cached content, force a request
    case ignore
}

internal extension Data {
    func hexString() -> String {
        var bytes = [UInt8](repeating: 0, count: self.count)
        (self as NSData).getBytes(&bytes, length: self.count)

        let convert_table = "0123456789abcdef"
        var s = ""
        for byte in bytes {
            s.append(convert_table.characters[convert_table.characters.index(convert_table.startIndex, offsetBy: Int(byte >> 4))])
            s.append(convert_table.characters[convert_table.characters.index(convert_table.startIndex, offsetBy: Int(byte & 0x0f))])
        }
        return s
    }
}


/// Base Request class that handles caching
open class IONRequest {
    static var cacheDB: [JSONObject]?

    // MARK: - API

    /// Async fetch JSON from ION Server
    ///
    /// - parameter endpoint: the API endpoint to query
    /// - parameter queryParameters: any query parameters to include in the query or nil
    /// - parameter cached: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`
    open class func fetchJSON(_ endpoint: String, queryParameters: [String: String]?, cached: IONCacheBehaviour, callback: @escaping ((Result<JSONObject, IONError>) -> NSDate?)) {
        guard let urlString = self.buildURL(endpoint, queryParameters: queryParameters),
              let url = URL(string: urlString),
              let cacheName = self.cacheName(url),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        let fromCache: ((String) -> Result<JSONObject, IONError>) = { cacheName in
            // Check disk cache before running HTTP request
            if FileManager.default.fileExists(atPath: cacheName) {
                // return from cache instantly
                do {
                    // fetch data from cache
                    let data = try String(contentsOfFile: cacheName)
                    var json = JSONDecoder(data).jsonObject

                    // patch last_updated into response
                    json = self.augmentJSONWithChangeDate(json, urlString: urlString)
                    return .success(json)
                } catch {
                    // do nothing, fallthrough to HTTP request
                }
            }
            return .failure(.noData(nil))
        }

        if cached == .prefer || cached == .force {
            let result = fromCache(cacheName)
            if case .success(let json) = result {
                // call callback in correct queue
                responseQueueCallback(callback, parameter: .success(json))
                return
            } else if cached == .force {
                responseQueueCallback(callback, parameter: .failure(.serverUnreachable))
                return
            }
        }

        var headers = self.headers()
        headers["Accept"] = "application/json"
        if let index = self.getCacheDBEntry(urlString) {
            if let rawLastUpdated = index["last_updated"],
               case .jsonNumber(let timestamp) = rawLastUpdated {
                let lastUpdated = Date(timeIntervalSince1970: TimeInterval(timestamp))
                headers["If-Modified-Since"] = lastUpdated.rfc822DateString()
            }
        }

        let request = alamofire.request(.GET, urlString, headers: headers)

        request.responseDEJSON { response in
            if case .Failure(let error) = response.result {
                // Request failed with `.ServerUnreachable` and caching set to `.Ignore`.
                // Try to load request again witch caching set to `.Prefer`
                // to load json from the cache if already cached.
                if case .ServerUnreachable = error, cached == .Ignore {
                    self.fetchJSON(endpoint, queryParameters: queryParameters, cached: .Prefer, callback: callback)
                } else {
                    responseQueueCallback(callback, parameter: .Failure(error))
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
                let patchedResult: Result<JSONObject, IONError> = .Success(self.augmentJSONWithChangeDate(jsonObject, urlString: urlString))
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
    open class func fetchBinary(_ urlString: String, queryParameters: [String: String]?, cached: IONCacheBehaviour, checksumMethod: String, checksum: String, callback: @escaping ((Result<String, IONError>) -> Void)) {
        let headers = self.headers()
        guard let url = URL(string: urlString),
              let cacheName = self.cacheName(url),
              let alamofire = ION.config.alamofire else {
                responseQueueCallback(callback, parameter: .failure(.didFail))
                return
        }

        if cached == .force || cached == .prefer {
            let cacheResult = self.fetchFromCache(urlString, checksumMethod: checksumMethod, checksum: checksum)
            if case .success = cacheResult {
                responseQueueCallback(callback, parameter: cacheResult)
                return
            } else if cached == .force {
                responseQueueCallback(callback, parameter: .failure(.serverUnreachable))
                return
            }
        }

        // destination block for Alamofire request
        let destination = { (fileURL: URL, response: HTTPURLResponse) -> URL in
            return URL(fileURLWithPath: cacheName + ".tmp")
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
                if let unwrapped = response, unwrapped.allHeaderFields["Content-Length"] == nil,
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
    open class func cachedFile(_ urlString: String) -> Data? {
        guard let url = URL(string: urlString),
              let cacheName = self.cacheName(url) else {
            return nil
        }

        var data: Data? = nil
        if FileManager.default.fileExists(atPath: cacheName) {
            do {
                data = try Data(contentsOf: URL(fileURLWithPath: cacheName), options: NSData.ReadingOptions.mappedIfSafe)
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
    open class func postJSON(_ endpoint: String, queryParameters: [String: String]?, body: [String: AnyObject], callback: @escaping ((Result<JSONResponse, IONError>) -> Void)) {
        guard let urlString = self.buildURL(endpoint, queryParameters: queryParameters),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .failure(.didFail))
            return
        }
        var headers = self.headers()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"

        let request = alamofire.request(.POST, urlString, parameters: body, encoding: .json, headers: headers)
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
    fileprivate class func buildURL(_ endpoint: String, queryParameters: [String: String]?) -> String? {
        guard let serverURL = ION.config.serverURL else {
            return nil
        }

        // append endpoint to base url
        let url = serverURL.appendingPathComponent(endpoint)

        // add query parameters
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        var queryItems: [URLQueryItem] = []

        queryParameters?.forEach({ (key, value) in
            queryItems.append(URLQueryItem(name: key, value: value))
        })

        components.queryItems = queryItems

        // return canonical url
        let urlString = components.url?.absoluteString
        return urlString
    }

    /// Prepare headers for request
    ///
    /// - returns: Headers-Dictionary for use in Alamofire request
    fileprivate class func headers() -> [String: String] {
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
    fileprivate class func augmentJSONWithChangeDate(_ json: JSONObject, urlString: String) -> JSONObject {
        // augment json with timestamp for last update
        guard case .jsonDictionary(var dict) = json,
              let cacheDBEntry = self.getCacheDBEntry(urlString),
              let rawLastUpdated = cacheDBEntry["last_updated"],
              case .jsonNumber = rawLastUpdated else {
                // return unchanged input if it neither was not a dictionary or there is no entry in cache DB
                return json
        }

        dict["last_updated"] = cacheDBEntry["last_updated"]
        return .jsonDictionary(dict)
    }

    /// Load file from cache
    ///
    /// - parameter urlString: URL of file
    /// - parameter checksumMethod: used checksumming method
    /// - parameter checksum: checksum to compare to
    /// - returns: Success with cached file name or Failure
    internal class func fetchFromCache(_ urlString: String, checksumMethod: String, checksum: String) -> Result<String, IONError> {

        guard let url = URL(string: urlString), let host = url.host else {
            return .failure(.didFail)
        }

        // validate checksum
        guard let cacheDBEntry = self.getCacheDBEntry(urlString) else {
            return .failure(.invalidJSON(nil))
        }

        guard let rawFileName = cacheDBEntry["filename"],
            let rawChecksumMethod = cacheDBEntry["checksum_method"],
            let rawChecksum = cacheDBEntry["checksum"],
            case .jsonString(let filename)             = rawFileName,
            case .jsonString(let cachedChecksumMethod) = rawChecksumMethod,
            case .jsonString(let cachedChecksum)       = rawChecksum else {
                return .failure(.invalidJSON(nil))
        }

        let fileURL = self.cacheBaseDir(host, locale: ION.config.locale)

        let cacheName = fileURL.appendingPathComponent(filename).path

        // ios 8.4 inserts spaces into our checksums, so remove them again
        if (cachedChecksumMethod != checksumMethod) || (cachedChecksum.replacingOccurrences(of: " ", with: "") != checksum.replacingOccurrences(of: " ", with: "")) {
            if checksumMethod != "null" {
                // if checksum changed DO NOT USE cache
                do {
                    try FileManager.default.removeItem(atPath: cacheName)
                } catch {
                    // do nothing, perhaps the file did not exist
                }

                return .failure(.noData(nil))
            }
        }

        // Check disk cache
        guard FileManager.default.fileExists(atPath: cacheName) else {
            return .failure(.noData(nil))
        }

        return .success(cacheName)
    }


    // Make init private to avoid instanciating as all functions are class functions
    fileprivate init() {}
}
