//
//  amp.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Alamofire
import Markdown

/// AMP configuration object
///
/// access with `AMP.config`
public struct AMPConfig {
    /// Server base URL for API (http://127.0.0.1:8000/client/v1/)
    public var serverURL:NSURL!
    
    /// locale-code to work on, defined by server config
    public var locale:String = "en_EN"
    
    /// response queue to run all async responses in, by default a concurrent queue, may be set to main queue
    public var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
    
    /// global error handler (catches all errors that have not been caught by a `.onError` somewhere
    public var errorHandler:((String, AMPError) -> Void)!
    
    /// the session token usually set by `AMP.login` but may be overridden for custom login functionality
    public var sessionToken:String?
    
    /// last collection fetch
    public var lastOnlineUpdate: NSDate?
    
    /// collection cache timeout
    public var cacheTimeout: NSTimeInterval = 600
    
    /// styling for attributed string conversion of markdown text
    public var stringStyling: AttributedStringStyling
    
    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    let alamofire: Alamofire.Manager
    
    /// only the AMP class may init this
    internal init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        self.stringStyling = AttributedStringStyling()
        
        self.alamofire = Alamofire.Manager(configuration: configuration)
        self.resetErrorHandler()
    }
    
    /// Reset the error handler to the default logging handler
    public mutating func resetErrorHandler() {
        self.errorHandler = { (collection, error) in
            print("AMP unhandled error in collection '\(collection)': \(error)")
        }
    }
}

/// AMP base class, use all AMP functionality by using this object's class methods
public class AMP {
    /// AMP configuration, be sure to set up before using any AMP calls or risk a crash!
    static public var config = AMPConfig()

    // Internal cache for collections
    static internal var collectionCache = [String:AMPCollection]()

    /// Login user
    ///
    /// - Parameter username: the username to log in
    /// - Parameter password: the password to send
    /// - Parameter callback: block to call when login request finished (Bool parameter is success flag)
    public class func login(username: String, password: String, callback: (Bool -> Void)) {
        AMPRequest.postJSON("login", queryParameters: nil, body: [
            "login": [
                "username": username,
                "password": password
            ]
        ]) { result in
            guard result.isSuccess,
                  let json = result.value,
                  case .JSONDictionary(let dict) = json where dict["login"] != nil,
                  case .JSONDictionary(let loginDict) = dict["login"]! where loginDict["token"] != nil,
                  case .JSONString(let token) = loginDict["token"]! else {

                self.config.sessionToken = nil
                dispatch_async(self.config.responseQueue) {
                    callback(false)
                }
                return
            }
            
            self.config.sessionToken = token
            dispatch_async(self.config.responseQueue) {
                callback(true)
            }
        }
    }
    
    /// Fetch a collection sync
    ///
    /// If the collection is not in any cache initialization of values may
    /// be delayed. Access to items in a non initialized collection may have
    /// undefined results
    ///
    /// - Parameter identifier: the identifier of the collection
    /// - Returns: collection object from cache or empty collection object
    public class func collection(identifier: String) -> AMPCollection {
        if !self.hasCacheTimedOut() {
            if let cachedObject = self.collectionCache[identifier] {
                return cachedObject
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, useCache: !self.hasCacheTimedOut(), callback: nil)
        if self.hasCacheTimedOut() {
            self.config.lastOnlineUpdate = NSDate()
        }
        return newCollection
    }
    
    /// Fetch a collection and call block on finish
    ///
    /// - Parameter identifier: the identifier of the collection
    /// - Parameter callback: the block to call when the collection is fully initialized
    /// - Returns: fetched collection to be able to chain calls
    public class func collection(identifier: String, callback: (AMPCollection -> Void)) -> AMPCollection {
        if !self.hasCacheTimedOut() {
            if let cachedObject = self.collectionCache[identifier] {
                if cachedObject.hasFailed {
                    self.callError(identifier, error: .CollectionNotFound(identifier))
                } else {
                    dispatch_async(cachedObject.workQueue) {
                        dispatch_async(self.config.responseQueue) {
                            callback(cachedObject)
                        }
                    }
                }
                return cachedObject
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, useCache: !self.hasCacheTimedOut(), callback:callback)
        if self.hasCacheTimedOut() {
            self.config.lastOnlineUpdate = NSDate()
        }
        return newCollection
    }

    /// Error handler
    ///
    /// - Parameter identifier: the collection identifier that caused the error
    /// - Parameter error: An error object
    class func callError(identifier: String, error: AMPError) {
        dispatch_async(AMP.config.responseQueue) {
            AMP.config.errorHandler(identifier, error)
        }
    }

    
    /// Clear memory cache
    ///
    /// Call in cases of memory warnings to purge the memory cache, calls to cached objects will punch through to disk
    /// cache and have a parsing and initialization penalty on next call.
    public class func resetMemCache() {
        // FIXME: collection needs resetMemCache()
        for collection in self.collectionCache.values {
            collection.pageCache.removeAll()
        }
        self.collectionCache.removeAll()
    }
    
    /// Clear disk cache
    ///
    /// Removes all cached requests and files for the configured server, does not affect memory cache so be careful
    public class func resetDiskCache() {
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(self.config.serverURL!.host!, locale:self.config.locale)
    }
    
    /// Clear disk cache for specific host and current locale
    ///
    /// Removes all cached requests and files for the specified server, does not affect memory cache so be careful
    /// - Parameter host: a hostname to empty the cache for
    // TODO: Write test for resetDiskCache(host:)
    public class func resetDiskCache(host host:String) {
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(host)
    }

    /// Clear disk cache for specific host and locale
    ///
    /// Removes all cached requests and files for the specified server, does not affect memory cache so be careful
    /// - Parameter host: a hostname to empty the cache for
    /// - Parameter locale: the locale to reset
    // TODO: Write test for resetDiskCache(host:locale:)
    public class func resetDiskCache(host host:String, locale:String) {
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(host, locale:locale)
    }

    /// Clear disk cache for specific locale and all hosts
    ///
    /// Removes all cached requests and files for the specified locale and all servers, does not affect memory cache so be careful
    /// - Parameter locale: a locale code to empty the cache for
    // TODO: Write test for resetDiskCache(locale:)
    public class func resetDiskCache(locale locale: String) {
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(locale: locale)
    }
    
    
    // MARK: - Internal
    
    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - Parameter progressObject: NSProgress of the download
    /// - Parameter urlString: URL of the download for management purposes
    class func registerProgress(progressObject: NSProgress, urlString: String) {
        // TODO: send progress callbacks
    }
    
    // MARK: - Private
    
    /// Determine if collection cache has timed out
    ///
    /// - Returns: true if cache is old
    private class func hasCacheTimedOut() -> Bool {
        var timeout = false
        if let lastUpdate = self.config.lastOnlineUpdate {
            let currentDate = NSDate()
            if lastUpdate.dateByAddingTimeInterval(self.config.cacheTimeout).compare(currentDate) == NSComparisonResult.OrderedAscending {
                timeout = true
            }
        } else {
            timeout = true
        }
        return timeout
    }
    
    /// Init is private because only class functions should be used
    private init() {
    }
}