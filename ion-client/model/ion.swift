//
//  ion.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Markdown

/// ION base class, use all ION functionality by using this object's class methods
public class ION {
    /// ION configuration, be sure to set up before using any ION calls or risk a crash!
    static public var config = IONConfig()

    /// Internal cache for collections
    static internal var collectionCache = [String: IONCollection]()

    /// Pending downloads
    static internal var pendingDownloads = [String: (totalBytes: Int64, downloadedBytes: Int64)]()
    
    /// Login user
    ///
    /// - parameter username: the username to log in
    /// - parameter password: the password to send
    /// - parameter callback: block to call when login request finished (Bool parameter is success flag)
    public class func login(username: String, password: String, callback: (Bool -> Void)) {
        IONRequest.postJSON("login", queryParameters: nil, body: [
            "login": [
                "username": username,
                "password": password
            ]
        ]) { result in
            guard result.isSuccess,
                  let jsonResponse = result.value,
                  let json = jsonResponse.json,
                  case .JSONDictionary(let dict) = json,
                  let rawLogin = dict["login"],
                  case .JSONDictionary(let loginDict) = rawLogin,
                  let rawToken = loginDict["token"],
                  case .JSONString(let token) = rawToken else {

                self.config.sessionToken = nil
                responseQueueCallback(callback, parameter: false)
                
                return
            }
            
            self.config.sessionToken = token
            responseQueueCallback(callback, parameter: true)
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
    public class func collection(identifier: String) -> IONCollection {
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
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .Ignore : .Prefer)
        let newCollection = IONCollection(
            identifier: identifier,
            locale: ION.config.locale,
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
    public class func collection(identifier: String, callback: (Result<IONCollection, IONError> -> Void)) -> IONCollection {
        let cachedCollection = self.collectionCache[identifier]
        
        // return memcache if not timed out
        if !self.hasCacheTimedOut(identifier) {
            if let cachedCollection = cachedCollection {
                if cachedCollection.hasFailed {
                    responseQueueCallback(callback, parameter: .Failure(.CollectionNotFound(identifier)))
                } else {
                    responseQueueCallback(callback, parameter: .Success(cachedCollection))
                }
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValueForKey(identifier)
        }
        
        // try an online update
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .Ignore : .Prefer)
        let newCollection = IONCollection(identifier: identifier, locale: ION.config.locale, useCache: cache) { result in
            guard case .Success(let collection) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            responseQueueCallback(callback, parameter: .Success(collection))
            
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

    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - parameter progressObject: NSProgress of the download
    /// - parameter urlString: URL of the download for management purposes
    class func registerProgress(bytesReceived: Int64, bytesExpected: Int64, urlString: String) {
        self.pendingDownloads[urlString] = (totalBytes: bytesExpected, downloadedBytes: bytesReceived)
        
        // sum up all pending downloads
        var totalBytes: Int64 = 0
        var downloadedBytes: Int64 = 0
        
        for (total, downloaded) in self.pendingDownloads.values {
            totalBytes += total
            downloadedBytes += downloaded
        }

        // call progress handler
        if let progressHandler = ION.config.progressHandler {
            let count = self.pendingDownloads.count
            dispatch_async(ION.config.responseQueue) {
                progressHandler(totalBytes: totalBytes, downloadedBytes: downloadedBytes, numberOfPendingDownloads: count)
            }
        }
        
        // remove from pending when total == downloaded
        if bytesReceived == bytesExpected {
            self.pendingDownloads.removeValueForKey(urlString)
            if let progressHandler = ION.config.progressHandler where self.pendingDownloads.isEmpty {
                dispatch_async(ION.config.responseQueue) {
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
        for block in ION.config.updateBlocks.values {
            dispatch_async(ION.config.responseQueue) {
                block(collectionIdentifier)
            }
        }
    }
    
    /// Check if collection changed and send change notifications
    ///
    /// - parameter collection1: first collection
    /// - parameter collection2: second collection
    private class func notifyForUpdates(collection1: IONCollection, collection2: IONCollection) {
        if collection1.equals(collection2) == false {
            // call change blocks
            ION.callUpdateBlocks(collection1.identifier)
        }
    }
    
    /// Init is private because only class functions should be used
    private init() {}
}
