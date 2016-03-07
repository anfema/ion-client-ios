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


/// AMP base class, use all AMP functionality by using this object's class methods
public class AMP {
    /// AMP configuration, be sure to set up before using any AMP calls or risk a crash!
    static public var config = AMPConfig()

    /// Internal cache for collections
    static internal var collectionCache = [String:AMPCollection]()

    /// Pending downloads
    static internal var pendingDownloads = [String:(totalBytes: Int64, downloadedBytes: Int64)]()
    
    /// Login user
    ///
    /// - parameter username: the username to log in
    /// - parameter password: the password to send
    /// - parameter callback: block to call when login request finished (Bool parameter is success flag)
    public class func login(username: String, password: String, callback: (Bool -> Void)) {
        AMPRequest.postJSON("login", queryParameters: nil, body: [
            "login": [
                "username": username,
                "password": password
            ]
        ]) { result in
            guard result.isSuccess,
                  let jsonResponse = result.value,
                  let json = jsonResponse.json,
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
    /// - parameter identifier: the identifier of the collection
    /// - returns: collection object from cache or empty collection object
    public class func collection(identifier: String) -> AMPCollection {
        let cachedCollection = self.collectionCache[identifier]

        // return memcache if not timed out
        if !self.hasCacheTimedOut(identifier) {
            if let cachedCollection = cachedCollection {
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValueForKey(identifier)
        }
        
        // try an online update
        let cache = AMP.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .Ignore : .Prefer)
        let newCollection = AMPCollection(
            identifier: identifier,
            locale: AMP.config.locale,
            useCache: cache
        ) { result in
            guard let cachedCollection = cachedCollection where !cachedCollection.hasFailed,
                  case .Success(let collection) = result else {
                    // FIXME: What happens in error case?
                return
            }
            
            self.notifyForUpdates(collection, collection2: cachedCollection)
        }
    
        if self.hasCacheTimedOut(identifier) {
            self.config.lastOnlineUpdate[identifier] = NSDate()
        }
        
        return newCollection
    }
    
    /// Fetch a collection and call block on finish
    ///
    /// - parameter identifier: the identifier of the collection
    /// - parameter callback: the block to call when the collection is fully initialized
    /// - returns: fetched collection to be able to chain calls
    public class func collection(identifier: String, callback: (Result<AMPCollection, AMPError> -> Void)) -> AMPCollection {
        let cachedCollection = self.collectionCache[identifier]
        
        // return memcache if not timed out
        if !self.hasCacheTimedOut(identifier) {
            if let cachedCollection = cachedCollection {
                if cachedCollection.hasFailed {
                    self.callError(identifier, error: .CollectionNotFound(identifier))
                } else {
                    dispatch_async(cachedCollection.workQueue) {
                        dispatch_async(self.config.responseQueue) {
                            callback(.Success(cachedCollection))
                        }
                    }
                }
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValueForKey(identifier)
        }
        
        // try an online update
        let cache = AMP.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .Ignore : .Prefer)
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, useCache: cache) { result in
            guard case .Success(let collection) = result else {
                callback(.Failure(result.error!))
                return
            }
            callback(.Success(collection))
            
            guard let cachedCollection = cachedCollection where !cachedCollection.hasFailed else {
                return
            }
            self.notifyForUpdates(collection, collection2: cachedCollection)
        }
        
        if self.hasCacheTimedOut(identifier) {
            self.config.lastOnlineUpdate[identifier] = NSDate()
        }
        
        return newCollection
    }
    
    // MARK: - Internal

    /// Error handler
    ///
    /// - parameter identifier: the collection identifier that caused the error
    /// - parameter error: An error object
    class func callError(identifier: String, error: AMPError) {
        dispatch_async(AMP.config.responseQueue) {
            AMP.config.errorHandler(identifier, error)
        }
    }

    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - parameter progressObject: NSProgress of the download
    /// - parameter urlString: URL of the download for management purposes
    class func registerProgress(bytesReceived: Int64, bytesExpected: Int64, urlString: String) {
        self.pendingDownloads[urlString] = (totalBytes: bytesExpected, downloadedBytes: bytesReceived)
        
        // sum up all pending downloads
        var totalBytes:Int64 = 0
        var downloadedBytes:Int64 = 0
        
        for (total, downloaded) in self.pendingDownloads.values {
            totalBytes += total
            downloadedBytes += downloaded
        }

        // call progress handler
        if let progressHandler = AMP.config.progressHandler {
            let count = self.pendingDownloads.count
            dispatch_async(AMP.config.responseQueue) {
                progressHandler(totalBytes: totalBytes, downloadedBytes: downloadedBytes, numberOfPendingDownloads: count)
            }
        }
        
        // remove from pending when total == downloaded
        if bytesReceived == bytesExpected {
            self.pendingDownloads.removeValueForKey(urlString)
            if let progressHandler = AMP.config.progressHandler where self.pendingDownloads.count == 0 {
                dispatch_async(AMP.config.responseQueue) {
                    progressHandler(totalBytes: 0, downloadedBytes: 0, numberOfPendingDownloads: 0)
                }
            }
        }
    }
    
    // MARK: - Private
    
    /// Call all update notification blocks
    ///
    /// - parameter collectionIdentifier: collection id to send to update block
    private class func callUpdateBlocks(collectionIdentifier: String) {
        for block in AMP.config.updateBlocks.values {
            dispatch_async(AMP.config.responseQueue) {
                block(collectionIdentifier)
            }
        }
    }
    
    /// Check if collection changed and send change notifications
    ///
    /// - parameter collection1: first collection
    /// - parameter collection2: second collection
    private class func notifyForUpdates(collection1: AMPCollection, collection2: AMPCollection) {
        var collectionChanged = false
        
        // compare metadata count
        if (collection1.pageMeta.count != collection2.pageMeta.count) || (collection1.lastChanged != collection2.lastChanged) {
            collectionChanged = true
        } else {
            // compare old collection and new collection page change dates and identifiers
            for i in 0..<collection1.pageMeta.count {
                let c1 = collection1.pageMeta[i]
                let c2 = collection2.pageMeta[i]
                if c1.identifier != c2.identifier || c1.lastChanged.compare(c2.lastChanged) != .OrderedSame {
                    collectionChanged = true
                    break
                }
            }
        }
        if collectionChanged {
            // call change blocks
            AMP.callUpdateBlocks(collection1.identifier)
        }
    }
    
    /// Init is private because only class functions should be used
    private init() {
    }
}