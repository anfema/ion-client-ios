//
//  amp.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import Alamofire

private class AMPMemCache {
    static let sharedInstance = AMPMemCache()
    var collectionCache = [AMPCollection]()
    
    private init() {
        // do nothing but make init private
    }
}


public struct AMPConfig {
    var serverURL:NSURL!
    var locale:String = "en_EN"
    var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
    
    var sessionToken:String?
    
    let alamofire: Alamofire.Manager
    
    init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        self.alamofire = Alamofire.Manager(configuration: configuration)
    }
}


/// AMP base class, almost everything will start here
///
/// Documentation missing, so here's a picture of a cat:
/// ![cat](http://lorempixel.com/300/200/cats/)
public class AMP {
    static var config = AMPConfig()

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
        ]) { (response, result) in
            guard let response = response where response.statusCode == 200,
                  case .Success(let json) = result,
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
    
    /// Fetch a collection
    ///
    /// If the collection is not in any cache initialization of values may
    /// be delayed. Access to items in a non initialized collection may have
    /// undefined results
    ///
    /// - Parameter identifier: the identifier of the collection
    /// - Returns: collection object from cache or empty collection object
    public class func collection(identifier: String) -> AMPCollection {
        for c in AMPMemCache.sharedInstance.collectionCache {
            if c.identifier == identifier {
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale)
        AMPMemCache.sharedInstance.collectionCache.append(newCollection)
        return newCollection
    }
    
    /// Fetch a collection and call block on finish
    ///
    /// - Parameter identifier: the identifier of the collection
    /// - Parameter callback: the block to call when the collection is fully initialized
    /// - Returns: fetched collection to be able to chain calls
    public class func collection(identifier: String, callback: (AMPCollection -> Void)) -> AMPCollection {
        for c in AMPMemCache.sharedInstance.collectionCache {
            if c.identifier == identifier {
                dispatch_async(self.config.responseQueue) {
                    callback(c)
                }
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, callback:callback)
        AMPMemCache.sharedInstance.collectionCache.append(newCollection)
        return newCollection
    }
    
    /// Clear memory cache
    ///
    /// Call in cases of memory warnings to purge the memory cache, calls to cached objects will punch through to disk
    /// cache and have a parsing and initialization penalty on next call.
    public class func resetMemCache() {
        AMPMemCache.sharedInstance.collectionCache.removeAll()
    }
    
    /// Clear disk cache
    ///
    /// Removes all cached requests and files for the configured server, does not affect memory cache so be careful
    public class func resetDiskCache() {
        AMPRequest.resetCache(self.config.serverURL!.host!)
    }
    
    /// Refresh disk and memory caches
    ///
    /// This only updates disk and memory cache for already loaded collections and pages in memory cache
    /// So if you want to bulk update a bunch of pages make sure they are loaded in memory already.
    /// This is done of performance reasons and because the caching system does not currently know what exactly is
    /// in the cache.
    ///
    /// - Parameter callback: Block to call when update is finished
    public class func refreshCache(callback: (AMPCollection -> Void)) {
       
        let queue = dispatch_queue_create("com.anfema.amp.CacheRefresh", nil)
        dispatch_suspend(queue)
        for index in AMPMemCache.sharedInstance.collectionCache.indices {
            let collection = AMPMemCache.sharedInstance.collectionCache[index]
            let name = collection.identifier

            dispatch_async(queue) {
                let locale = collection.locale
                
                // reinitialize cached collection, turning cache off for this call
                let _ = AMPCollection(identifier: name, locale: locale, useCache: false) { collection in
                    AMPMemCache.sharedInstance.collectionCache.replaceRange(Range<Int>(start: index, end: index + 1), with: [collection])
                    callback(collection)
                }
            }
            
            for page in collection.pageCache {
                dispatch_async(queue) {
                    AMP.collection(name) { collection in
                        for p in collection.pages {
                            if (p.identifier == page.identifier) && (p.lastChanged.compare(page.lastUpdate) != .OrderedAscending) {
                                collection.page(page.identifier) { page in
                                    // do nothing, just download page
                                    print("AMP: Page refreshed: \(collection.identifier) -> \(page.identifier)")
                                }
                            } else {
                                print("AMP: Page current: \(collection.identifier) -> \(page.identifier)")
                            }
                        }
                    }
                }
            }
        }
        dispatch_resume(queue)
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
    
    /// Init is private because only class functions should be used
    private init() {
    }
}