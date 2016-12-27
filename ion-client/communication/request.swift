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
import Alamofire


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
    /// - parameter cacheBehaviour: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`
    open class func fetchJSON(fromEndpoint endpoint: String, queryParameters: [String: String]?, cacheBehaviour: IONCacheBehaviour, callback: @escaping ((Result<JSONObject>) -> Date?)) {
        guard let urlString = self.buildURL(withEndpoint: endpoint, queryParameters: queryParameters),
              let url = URL(string: urlString),
              let cacheName = self.cachePath(forURL: url),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        let fromCache: ((String) -> Result<JSONObject>) = { cacheName in
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
            return .failure(IONError.noData(nil))
        }

        if cacheBehaviour == .prefer || cacheBehaviour == .force {
            let result = fromCache(cacheName)
            if case .success(let json) = result {
                // call callback in correct queue
                responseQueueCallback(callback, parameter: .success(json))
                return
            } else if cacheBehaviour == .force {
                responseQueueCallback(callback, parameter: .failure(IONError.serverUnreachable))
                return
            }
        }

        var headers = self.headers()
        headers["Accept"] = "application/json"
        if let index = self.getCacheDBEntry(forURL: urlString) {
            if let rawLastUpdated = index["last_updated"],
               case .jsonNumber(let timestamp) = rawLastUpdated {
                let lastUpdated = Date(timeIntervalSince1970: TimeInterval(timestamp))
                headers["If-Modified-Since"] = (lastUpdated as NSDate).rfc822DateString()
            }
        }

        let request = alamofire.request(urlString, method: .get, headers: headers)

        request.responseDEJSON { response in
            if case .failure(let error) = response.result {
                // Request failed with `.ServerUnreachable` and caching set to `.Ignore`.
                // Try to load request again witch caching set to `.Prefer`
                // to load json from the cache if already cached.
                if case IONError.serverUnreachable = error, cacheBehaviour == .ignore {
                    self.fetchJSON(fromEndpoint: endpoint, queryParameters: queryParameters, cacheBehaviour: .prefer, callback: callback)
                } else {
                    responseQueueCallback(callback, parameter: .failure(error))
                }

                return
            }

            guard let request = response.request else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            // save response to cache
            self.saveJSONToCache(using: request, ion_client.Result(result: response.result))

            // object can only be saved if there is a request url and the status code of the response is a 200
            var jsonObject: JSONObject? = nil
            if response.result.isSuccess,
               let jsonResponse = response.result.value,
               let json = jsonResponse.json {
                jsonObject = json
            } else {
                // fallback to cache
                if case .success(let json) = fromCache(cacheName) {
                    jsonObject = json
                }
            }

            if let jsonObject = jsonObject {
                // patch last_updated into response
                let patchedResult: Result<JSONObject> = .success(self.augmentJSONWithChangeDate(jsonObject, urlString: urlString))
                // call callback in correct queue
                ION.config.responseQueue.async {
                    if let date = callback(patchedResult) {
                        self.saveJSONToCache(using: request, checksumMethod: "null", checksum: "", lastUpdate: date)
                    }
                }
            } else {
                responseQueueCallback(callback, parameter: .failure(IONError.noData(nil)))
            }
        }

        request.resume()
    }

    /// Async fetch a binary file from ION Server
    ///
    /// - parameter urlString: the URL to fetch, has to be a complete and valid URL
    /// - parameter queryParameters: any query parameters to include in the query or nil
    /// - parameter cacheBehaviour: set to true if caching should be enabled (cached data is returned instantly, no query is sent)
    /// - parameter callback: a block to call when the request finishes, will be called in `ION.config.responseQueue`,
    ///                       Payload of response is the filename of the downloaded file on disk
    open class func fetchBinary(fromURL urlString: String, queryParameters: [String: String]?, cacheBehaviour: IONCacheBehaviour, checksumMethod: String, checksum: String, callback: @escaping ((Result<String>) -> Void)) {
        let headers = self.headers()
        guard let url = URL(string: urlString),
              let cacheName = self.cachePath(forURL: url),
              let alamofire = ION.config.alamofire else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
        }

        if cacheBehaviour == .force || cacheBehaviour == .prefer {
            let cacheResult = self.fetchFileFromCache(url: urlString, checksumMethod: checksumMethod, checksum: checksum)
            if case .success = cacheResult {
                responseQueueCallback(callback, parameter: cacheResult)
                return
            } else if cacheBehaviour == .force {
                responseQueueCallback(callback, parameter: .failure(IONError.serverUnreachable))
                return
            }
        }

        let destinationURL = URL(fileURLWithPath: cacheName + ".tmp")
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            // TODO: Check if correct options were set here
            return (destinationURL, [.createIntermediateDirectories, .removePreviousFile])
        }
        
        
        // Start download task
        let downloadTask = alamofire.download(urlString,
                                              method: .get,
                                              parameters: queryParameters,
                                              encoding: URLEncoding.default,
                                              headers: headers,
                                              to: destination)
        
        downloadTask.downloadProgress { (progress) in
            if progress.totalUnitCount < 0 {
                // server sent no content-length header, we expect one byte more than we got
                ION.registerProgress(progress.completedUnitCount, bytesExpected: progress.completedUnitCount + 1, urlString: urlString)
            } else {
                // server sent a content-length header, trust it
                ION.registerProgress(progress.completedUnitCount, bytesExpected: progress.totalUnitCount, urlString: urlString)
            }
        }
        

        downloadTask.response { (response) in
            // check for download errors
            if response.error != nil || response.response?.statusCode != 200 {
                // TODO: Request bogus binary to test error case
                
                // remove temp file
                do {
                    try FileManager.default.removeItem(atPath: cacheName + ".tmp")
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                
                guard let response = response.response else {
                    responseQueueCallback(callback, parameter: .failure(IONError.serverUnreachable))
                    return
                }
                
                if response.statusCode == 401 || response.statusCode == 403 {
                    responseQueueCallback(callback, parameter: .failure(IONError.notAuthorized))
                    return
                }
                
                // call final update for progress, we're using 1 here because the user likely wants to
                // calculate a percentage and thus divides those numbers
                if response.allHeaderFields["Content-Length"] == nil {
                    ION.registerProgress(1, bytesExpected: 1, urlString: urlString)
                }
                
                // try falling back to cache
                ION.config.responseQueue.async {
                    let result = fetchFileFromCache(url: urlString, checksumMethod: checksumMethod, checksum: checksum)
                    if case .failure = result {
                        if response.statusCode == 304 {
                            callback(.success(""))
                            return
                        }
                    }
                    callback(result)
                }
            } else {
                // move temp file
                do {
                    try FileManager.default.removeItem(atPath: cacheName)
                } catch {
                    // do nothing, perhaps the file did not exist
                }
                do {
                    try FileManager.default.moveItem(atPath: cacheName + ".tmp", toPath: cacheName)
                } catch {
                    // ok moving failed
                    responseQueueCallback(callback, parameter: .failure(IONError.noData(error)))
                    return
                }
                
                guard let request = response.request else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
                }
                
                // no error, save file to cache db
                var ckSumMethod = checksumMethod
                var ckSum = checksum
                if ckSumMethod == "null" {
                    // update checksum if method was "null"
                    if let cachedFileData = self.cachedData(forURL: urlString) {
                        ckSumMethod = "sha256"
                        ckSum = (cachedFileData as NSData).cryptoHash(.SHA256).hexString()
                    } else {
                        // TODO: return error or do nothing when checksum could not be updated?
                    }
                }
                
                // finish up progress reporting
                if let unwrapped = response.response, unwrapped.allHeaderFields["Content-Length"] == nil,
                    let cachedFileData = self.cachedData(forURL: urlString) {
                    let bytes: Int64 = Int64(cachedFileData.count)
                    ION.registerProgress(bytes, bytesExpected: bytes, urlString: urlString)
                }
                
                self.saveJSONToCache(using: request, checksumMethod: ckSumMethod, checksum: ckSum)
                
                // call callback in correct queue
                responseQueueCallback(callback, parameter: .success(cacheName))
            }
        }

        downloadTask.resume()
    }

    /// Fetch a file from the cache or return nil
    ///
    /// - parameter urlString: url of the file to fetch from cache
    /// - returns: `NSData` with memory mapped file or `nil` if not in cache
    open class func cachedData(forURL urlString: String) -> Data? {
        guard let url = URL(string: urlString),
              let cacheName = self.cachePath(forURL: url) else {
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
    open class func postJSON(toEndpoint endpoint: String, queryParameters: [String: String]?, body: [String: Any], callback: @escaping ((Result<JSONResponse>) -> Void)) {
        guard let urlString = self.buildURL(withEndpoint: endpoint, queryParameters: queryParameters),
              let alamofire = ION.config.alamofire else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }
        var headers = self.headers()
        headers["Accept"] = "application/json"
        headers["Content-Type"] = "application/json"

        
        let request = alamofire.request(urlString, method: .post, parameters: body, encoding: JSONEncoding.default, headers: headers)
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
    fileprivate class func buildURL(withEndpoint endpoint: String, queryParameters: [String: String]?) -> String? {
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
              let cacheDBEntry = self.getCacheDBEntry(forURL: urlString),
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
    /// - parameter URLString: URL of file
    /// - parameter checksumMethod: used checksumming method
    /// - parameter checksum: checksum to compare to
    /// - returns: Success with cached file name or Failure
    internal class func fetchFileFromCache(url urlString: String, checksumMethod: String, checksum: String) -> Result<String> {

        guard let url = URL(string: urlString), let host = url.host else {
            return .failure(IONError.didFail)
        }

        // validate checksum
        guard let cacheDBEntry = self.getCacheDBEntry(forURL: urlString) else {
            return .failure(IONError.invalidJSON(nil))
        }

        guard let rawFileName = cacheDBEntry["filename"],
            let rawChecksumMethod = cacheDBEntry["checksum_method"],
            let rawChecksum = cacheDBEntry["checksum"],
            case .jsonString(let filename)             = rawFileName,
            case .jsonString(let cachedChecksumMethod) = rawChecksumMethod,
            case .jsonString(let cachedChecksum)       = rawChecksum else {
                return .failure(IONError.invalidJSON(nil))
        }

        let fileURL = self.cacheBaseDir(forHost: host, locale: ION.config.locale)

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

                return .failure(IONError.noData(nil))
            }
        }

        // Check disk cache
        guard FileManager.default.fileExists(atPath: cacheName) else {
            return .failure(IONError.noData(nil))
        }

        return .success(cacheName)
    }


    // Make init private to avoid instanciating as all functions are class functions
    fileprivate init() {}
}
