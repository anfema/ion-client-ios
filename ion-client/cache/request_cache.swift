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

/// Caching extension for IONRequest
extension IONRequest {

    /// Reset complete ION cache for a specific language and all hosts
    ///
    /// - parameter locale: locale to clear cache for
    public class func resetCache(forLocale locale: String) {
        // remove complete cache dir for this host
        let fileURL = self.cacheBaseDir(forLocale: locale)

        do {
            try FileManager.default.removeItem(atPath: fileURL.path)
        } catch {
            // non-fatal, could not remove item at path, so probably path did not exist
        }

        if locale == ION.config.locale {
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
    internal class func cachePath(forURL url: URL) -> String? {
        guard let host = url.host else {
            return nil
        }

        let fileURL = self.cacheBaseDir(forHost: host, locale: ION.config.locale)

        // try to create the path if it does not exist
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.createDirectory(atPath: fileURL.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                if ION.config.loggingEnabled {
                    print("ION: Could not create cache dir!")
                }
            }
        }

        // generate cache path
        return fileURL.appendingPathComponent(url.absoluteString.cryptoHash(.MD5).hexString()).path
    }

    /// Internal function to fetch a cache DB entry
    ///
    /// - parameter urlString: the URL to find in the cache DB
    /// - returns: cache db entry (JSON dictionary unpacked into dictionary)
    internal class func getCacheDBEntry(forURL urlString: String) -> [String: JSONObject]? {
        // load db if not already loaded
        if self.cacheDB == nil {
            self.loadCacheDB()
        }

        guard let cacheDB = self.cacheDB else {
            return nil
        }

        // find entry in cache db
        for case .jsonDictionary(let dict) in cacheDB {
            guard let rawURL = dict["url"],
                  case .jsonString(let entryURL) = rawURL, entryURL == urlString else {
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
    internal class func saveJSONToCache(using request: URLRequest, _ result: Result<JSONResponse>) {

        // object can only be saved if there is a request url and the status code of the response is a 200
        guard result.isSuccess,
            case .success(let jsonResponse) = result else {
                return
        }
        
        if jsonResponse.statusCode == 200,
           let jsonObject = jsonResponse.json,
           let json = JSONEncoder(jsonObject).jsonString,
           let requestURL = request.url {

            do {
                // save object to disk
                if let cacheName = self.cachePath(forURL: requestURL) {
                    try json.write(toFile: cacheName, atomically: true, encoding: String.Encoding.utf8)

                    // save object to cache DB
                    self.saveJSONToCache(using: request, checksumMethod: "null", checksum: "")
                }
            } catch {
                // do nothing, could not be saved to cache -> nonfatal
            }
        } else if jsonResponse.statusCode == 304 {
            self.saveJSONToCache(using: request, checksumMethod: "null", checksum: "")
        }
    }

    internal class func saveJSONToCache(using data: Data, url: String, checksum: String?, lastUpdated: Date? = nil) {
        // load cache DB if not loaded yet
        if self.cacheDB == nil {
            self.loadCacheDB()
        }

        // date used for the timestamp
        let date = lastUpdated ?? Date()

        // fetch current timestamp truncated to maximum resolution of 1 ms
        let timestamp: Double = trunc(date.timeIntervalSince1970 * 1000.0) / 1000.0

        // pop current cache DB entry
        var obj: [String: JSONObject] = self.getCacheDBEntry(forURL: url) ?? [:]
        self.removeCacheDBEntries(withURL: url)

        guard let parsedURL = URL(string: url) else {
            return
        }

        guard let hash = url.cryptoHash(.MD5),
            let host = parsedURL.host else {
            return
        }

        let filename = self.cacheBaseDir(forHost: host, locale: ION.config.locale)

        let path = filename.path

        if !FileManager.default.fileExists(atPath: path) {
            do {
                try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                return
            }
        }

        let filePath = filename.appendingPathComponent((hash.hexString())).path

        guard let fileURL = URL(string: filePath) else
        {
            return
        }
        
        try? data.write(to: fileURL)

        // populate object with current data
        obj["url"]             = .jsonString(url)
        obj["host"]            = .jsonString(host)
        obj["filename"]        = .jsonString(hash.hexString())
        obj["last_updated"]    = .jsonNumber(timestamp)

        if let checksum = checksum {
            let checksumParts = checksum.components(separatedBy: ":")
            if checksumParts.count > 1 {
                obj["checksum_method"] = .jsonString(checksumParts[0])
                obj["checksum"]        = .jsonString(checksumParts[1])
            }
        }

        // append to cache DB and save
        self.cacheDB?.append(JSONObject.jsonDictionary(obj))
    }

    /// Internal function to add an object to the cache DB
    ///
    /// - parameter request: request (used to extract URL)
    /// - parameter checksumMethod: the name of the used method used to create the `checksum`
    /// - parameter checksum: the checksum calculated by the `checksumMethod`
    /// - parameter lastUpdate: the date when the last update was performed or nil
    internal class func saveJSONToCache(using request: URLRequest, checksumMethod: String, checksum: String, lastUpdate: Date? = nil) {
        // load cache DB if not loaded yet
        if self.cacheDB == nil {
            self.loadCacheDB()
        }

        // fetch current timestamp truncated to maximum resolution of 1 ms
        var timestamp: Double = 0.0
        if let lastUpdate = lastUpdate {
            timestamp = trunc(lastUpdate.timeIntervalSince1970 * 1000.0) / 1000.0
        } else {
            timestamp = trunc(Date().timeIntervalSince1970 * 1000.0) / 1000.0
        }

        guard let requestURL = request.url else
        {
            return
        }
        
        let urlString = requestURL.absoluteString
        
        // pop current cache DB entry
        var obj: [String: JSONObject] = self.getCacheDBEntry(forURL: urlString) ?? [:]
        self.removeCacheDBEntries(withURL: urlString)

        guard let requestHost = requestURL.host else {
            return
        }

        // populate object with current data
        obj["url"]             = .jsonString(urlString)
        obj["host"]            = .jsonString(requestHost)
        obj["filename"]        = .jsonString(urlString.cryptoHash(.MD5).hexString())
        obj["last_updated"]    = .jsonNumber(timestamp)
        obj["checksum_method"] = .jsonString(checksumMethod)
        obj["checksum"]        = .jsonString(checksum)

        // append to cache DB and save
        self.cacheDB?.append(JSONObject.jsonDictionary(obj))
        self.saveCacheDB()
    }

    // MARK: - Private API

    /// Private function to load cache DB from disk
    fileprivate class func loadCacheDB(forLocale locale: String = ION.config.locale) {
        let fileURL = self.cacheFileURL(forFilename: "cacheIndex.json", locale: locale)

        let cacheIndexPath = fileURL.path

        do {
            // try loading from disk
            let jsonString = try String(contentsOfFile: cacheIndexPath)

            // decode json object and set internal static variable
            let jsonObject = JSONDecoder(jsonString).jsonObject
            if case .jsonArray(let array) = jsonObject {
                self.cacheDB = array
            } else {
                // invalid json, reset the cache db and remove disk cache completely
                do {
                    
                    let path = self.cacheBaseDir(forLocale: locale).path
                    try FileManager.default.removeItem(atPath: path)
                    
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
                if ION.config.loggingEnabled {
                    print("ION: Could not load cache DB index, corrupt file")
                }
                self.cacheDB = []
            }
        } catch {
            // no index file, create empty cache db
            self.cacheDB = []
        }
    }

    /// Private function to save the cache DB to disk
    internal class func saveCacheDB(forLocale locale: String = ION.config.locale) {
        // can not save nothing
        guard let cacheDB = self.cacheDB else {
            return
        }

        // create a valid JSON object and serialize
        let jsonObject = JSONObject.jsonArray(cacheDB)

        guard let jsonString = JSONEncoder(jsonObject).jsonString else {
            return
        }

        let basePath = self.cacheBaseDir(forLocale: locale).path

        do {
            let file = self.cacheFileURL(forFilename: "cacheIndex.json", locale: locale).path

            // make sure the cache dir is there
            if !FileManager.default.fileExists(atPath: basePath) {
                try FileManager.default.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
            }

            // try saving to disk
            try jsonString.write(toFile: file, atomically: true, encoding: String.Encoding.utf8)
        } catch {
            // saving failed, remove disk cache completely because we don't have a clue what's in it
            do {
                try FileManager.default.removeItem(atPath: basePath)
            } catch {
                // ok nothing fatal could happen, do nothing
            }
            if ION.config.loggingEnabled {
                print("ION: Could not save cache DB index")
            }
        }
    }


    /// Private function to remove entries with a specific url from the cache DB
    fileprivate class func removeCacheDBEntries(withURL urlString: String) {
        removeCacheDBEntries(forKey: "url", value: urlString)
    }


    /// Private function to remove entries from the cache DB
    fileprivate class func removeCacheDBEntries(forKey key: String, value: String) {
        guard let cacheDB = self.cacheDB else {
            return
        }

        self.cacheDB = cacheDB.filter({ entry -> Bool in
            guard case .jsonDictionary(let dict) = entry,
                let valueString = dict[key],
                case .jsonString(let entryValue) = valueString, entryValue == value else {
                    return true
            }
            return false
        })
    }

    /// Internal function to return the base directory for the ION cache
    ///
    /// - parameter host: the API host to fetch the cache dir for
    /// - parameter locale: the locale of the language that should be used
    /// - returns: File URL to the cache dir
    internal class func cacheBaseDir(forHost host: String, locale: String) -> URL {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = directoryURLs[0].appendingPathComponent("com.anfema.ion/\(locale)/\(host)")
        return fileURL
    }

    fileprivate class func cacheBaseDir(forLocale locale: String) -> URL {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = directoryURLs[0].appendingPathComponent("com.anfema.ion/\(locale)")
        return fileURL
    }

    fileprivate class func cacheFileURL(forFilename filename: String, locale: String) -> URL {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = directoryURLs[0].appendingPathComponent("com.anfema.ion/\(locale)/\(filename)")
        return fileURL
    }
}
