//
//  amp.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import Alamofire

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
    public var errorHandler:((String, AMPError.Code) -> Void)!
    
    /// the session token usually set by `AMP.login` but may be overridden for custom login functionality
    public var sessionToken:String?
    
    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    let alamofire: Alamofire.Manager
    
    init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        self.alamofire = Alamofire.Manager(configuration: configuration)
        self.resetErrorHandler()
    }
    
    public mutating func resetErrorHandler() {
        self.errorHandler = { (collection, error) in
            print("AMP unhandled error in collection '\(collection)': \(error)")
        }
    }
}

public class AMP {
    /// AMP configuration, be sure to set up before using any AMP calls or risk a crash!
    static public var config = AMPConfig()
    
    static private var collectionCache:[AMPCollection] = []
    static private var pageCache:[AMPPage] = []         /// memory cache for pages

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
        for c in self.collectionCache {
            if c.identifier == identifier {
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale)
        self.collectionCache.append(newCollection)
        return newCollection
    }
    
    /// Fetch a collection and call block on finish
    ///
    /// - Parameter identifier: the identifier of the collection
    /// - Parameter callback: the block to call when the collection is fully initialized
    /// - Returns: fetched collection to be able to chain calls
    public class func collection(identifier: String, callback: (AMPCollection -> Void)) -> AMPCollection {
        for c in self.collectionCache {
            if c.identifier == identifier {
                if c.hasFailed {
                    self.callError(identifier, error: AMPError.Code.CollectionNotFound(identifier))
                } else {
                    dispatch_async(self.config.responseQueue) {
                        callback(c)
                    }
                }
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, callback:callback)
        self.collectionCache.append(newCollection)
        return newCollection
    }

    /// Error handler
    ///
    /// - Parameter identifier: the collection identifier that caused the error
    /// - Parameter error: An error object
    class func callError(identifier: String, error: AMPError.Code) {
        dispatch_async(AMP.config.responseQueue) {
            AMP.config.errorHandler(identifier, error)
        }
    }

    
    /// Clear memory cache
    ///
    /// Call in cases of memory warnings to purge the memory cache, calls to cached objects will punch through to disk
    /// cache and have a parsing and initialization penalty on next call.
    public class func resetMemCache() {
        self.collectionCache.removeAll()
        self.pageCache.removeAll()
    }
    
    /// Clear disk cache
    ///
    /// Removes all cached requests and files for the configured server, does not affect memory cache so be careful
    public class func resetDiskCache() {
        AMPRequest.resetCache(self.config.serverURL!.host!, locale:self.config.locale)
    }
    
    /// Clear disk cache for specific host and current locale
    ///
    /// Removes all cached requests and files for the specified server, does not affect memory cache so be careful
    /// - Parameter host: a hostname to empty the cache for
    public class func resetDiskCache(host host:String) {
        AMPRequest.resetCache(host)
    }

    /// Clear disk cache for specific host and locale
    ///
    /// Removes all cached requests and files for the specified server, does not affect memory cache so be careful
    /// - Parameter host: a hostname to empty the cache for
    /// - Parameter locale: the locale to reset
    public class func resetDiskCache(host host:String, locale:String) {
        AMPRequest.resetCache(host, locale:locale)
    }

    /// Clear disk cache for specific locale and all hosts
    ///
    /// Removes all cached requests and files for the specified locale and all servers, does not affect memory cache so be careful
    /// - Parameter locale: a locale code to empty the cache for
    public class func resetDiskCache(locale locale: String) {
        AMPRequest.resetCache(locale: locale)
    }
    
    /// Refresh disk and memory caches
    ///
    /// This only updates disk and memory cache for already loaded collections and pages in memory cache
    /// So if you want to bulk update a bunch of pages make sure they are loaded in memory already.
    /// This is done of performance reasons and because the caching system does not currently know what exactly is
    /// in the cache.
    ///
    /// - Parameter callback: Block to call when update of a collection is finished, must not mean the
    ///                       pages in the collection have been updated already!
    public class func refreshCache(callback: (AMPCollection -> Void)) {
       
        // create new serial queue and suspend it to allow filling before processing
        let queue = dispatch_queue_create("com.anfema.amp.CacheRefresh", nil)
        dispatch_suspend(queue)
        
        for index in self.collectionCache.indices {
            let collection = self.collectionCache[index]
            let name = collection.identifier

            // at first update collection
            dispatch_async(queue) {
                let locale = collection.locale
                
                // reinitialize cached collection, turning cache off for this call
                let _ = AMPCollection(identifier: name, locale: locale, useCache: false) { collection in
                    self.collectionCache.replaceRange(Range<Int>(start: index, end: index + 1), with: [collection])
                    callback(collection)
                }
            }
        }

        // add fetches to the suspended queue to avoid changing the page cache while iterating over it
        for page in self.pageCache {
            dispatch_async(queue) {

                // fetch collection
                AMP.collection(page.collection.identifier) { collection in
                    for p in collection.pageMeta {
                        // validate page last update dates with those from the cache
                        if (p.identifier == page.identifier) && (p.lastChanged.compare(page.lastUpdate) != .OrderedAscending) {
                            collection.page(page.identifier) { page in
                                // do nothing, just download page
                                // print("AMP: Page refreshed: \(collection.identifier) -> \(page.identifier)")
                            }
                        } else {
                            // print("AMP: Page current: \(collection.identifier) -> \(page.identifier)")
                        }
                    }
                }
            }
        }
        
        
        // start the serial queue
        dispatch_resume(queue)
    }
    
    // TODO: missing collection refresh
    // TODO: missing page refresh
    
    // MARK: - Internal
    
    /// Fetch page from cached page list
    ///
    /// - Parameter collection: a collection object
    /// - Parameter identifier: the identifier of the page to fetch
    /// - Returns: page object or nil if not found
    class func getCachedPage(collection: AMPCollection, identifier: String) -> AMPPage? {
        for p in self.pageCache {
            if (p.collection.identifier == collection.identifier) && (p.identifier == identifier) {
                return p
            }
        }
        return nil
    }
    
    /// Save page to the page cache overwriting older versions
    ///
    /// - Parameter page: the page to add to the cache
    class func cachePage(page: AMPPage) {
        // check if we need to overwrite an old page
        self.pageCache = self.pageCache.filter({ p -> Bool in
            return !((p.identifier == page.identifier) && (p.collection.identifier == page.collection.identifier))
        })
        
        self.pageCache.append(page)
    }
    
    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - Parameter progressObject: NSProgress of the download
    /// - Parameter urlString: URL of the download for management purposes
    class func registerProgress(progressObject: NSProgress, urlString: String) {
        // TODO: send progress callbacks
    }
    
    // MARK: - Private
    
    /// Init is private because only class functions should be used
    private init() {
    }
}