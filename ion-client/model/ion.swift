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
open class ION {
    /// ION configuration, be sure to set up before using any ION calls or risk a crash!
    static open var config = IONConfig()

    /// Internal cache for collections
    static internal var collectionCache = [String: IONCollection]()

    /// Pending downloads
    static internal var pendingDownloads = [String: (totalBytes: Int64, downloadedBytes: Int64)]()

    /// Login user
    ///
    /// - parameter username: the username to log in
    /// - parameter password: the password to send
    /// - parameter callback: block to call when login request finished (Bool parameter is success flag)
    open class func login(_ username: String, password: String, callback: @escaping ((Bool) -> Void)) {
        IONRequest.postJSON(toEndpoint: "login", queryParameters: nil, body: [
            "login": [
                "username": username,
                "password": password
            ]
        ]) { result in
            guard result.isSuccess,
                  let jsonResponse = result.value,
                  let json = jsonResponse.json,
                  case .jsonDictionary(let dict) = json,
                  let rawLogin = dict["login"],
                  case .jsonDictionary(let loginDict) = rawLogin,
                  let rawToken = loginDict["token"],
                  case .jsonString(let token) = rawToken else {

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
    open class func collection(_ identifier: String) -> IONCollection {
        let cachedCollection = self.collectionCache[identifier]

        // return memcache if not timed out
        if !self.hasCacheTimedOut(identifier) {
            if let cachedCollection = cachedCollection {
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValue(forKey: identifier)
        }

        // try an online update
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .ignore : .prefer)
        let newCollection = IONCollection(
            identifier: identifier,
            locale: ION.config.locale,
            cacheBehaviour: cache
        ) { result in
            guard let cachedCollection = cachedCollection, !cachedCollection.hasFailed,
                  case .success(let collection) = result else {
                    // FIXME: What happens in error case?
                return
            }

            self.notifyForUpdates(collection, collection2: cachedCollection)
        }

        if self.hasCacheTimedOut(identifier) {
            self.config.lastOnlineUpdate[identifier] = Date()
        }

        return newCollection
    }

    /// Fetch a collection and call block on finish
    ///
    /// - parameter identifier: the identifier of the collection
    /// - parameter callback: the block to call when the collection is fully initialized
    /// - returns: fetched collection to be able to chain calls
    @discardableResult open class func collection(_ identifier: String, callback: @escaping ((Result<IONCollection>) -> Void)) -> IONCollection {
        let cachedCollection = self.collectionCache[identifier]

        // return memcache if not timed out
        if !self.hasCacheTimedOut(identifier) {
            if let cachedCollection = cachedCollection {
                if cachedCollection.hasFailed {
                    responseQueueCallback(callback, parameter: .failure(IONError.collectionNotFound(identifier)))
                } else {
                    responseQueueCallback(callback, parameter: .success(cachedCollection))
                }
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValue(forKey: identifier)
        }

        // try an online update
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(identifier)) ? .ignore : .prefer)
        let newCollection = IONCollection(identifier: identifier, locale: ION.config.locale, cacheBehaviour: cache) { result in
            guard case .success(let collection) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            responseQueueCallback(callback, parameter: .success(collection))

            guard let cachedCollection = cachedCollection, !cachedCollection.hasFailed else {
                return
            }
            self.notifyForUpdates(collection, collection2: cachedCollection)
        }

        if self.hasCacheTimedOut(identifier) {
            self.config.lastOnlineUpdate[identifier] = Date()
        }

        return newCollection
    }

    // MARK: - Internal

    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - parameter bytesReceived: Number of received bytes
    /// - parameter bytesExpected: Number of total expected bytes
    /// - parameter urlString: The URL of the file the progress should be reported
    ///
    class func registerProgress(_ bytesReceived: Int64, bytesExpected: Int64, urlString: String) {
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
            ION.config.responseQueue.async {
                progressHandler(totalBytes, downloadedBytes, count)
            }
        }

        // remove from pending when total == downloaded
        if bytesReceived == bytesExpected {
            self.pendingDownloads.removeValue(forKey: urlString)
            if let progressHandler = ION.config.progressHandler, self.pendingDownloads.isEmpty {
                ION.config.responseQueue.async {
                    progressHandler(0, 0, 0)
                }
            }
        }
    }

    // MARK: - Private

    /// Call all update notification blocks
    ///
    /// - parameter collectionIdentifier: collection id to send to update block
    fileprivate class func callUpdateBlocks(_ collectionIdentifier: String) {
        for block in ION.config.updateBlocks.values {
            ION.config.responseQueue.async {
                block(collectionIdentifier)
            }
        }
    }

    /// Check if collection changed and send change notifications
    ///
    /// - parameter collection1: first collection
    /// - parameter collection2: second collection
    fileprivate class func notifyForUpdates(_ collection1: IONCollection, collection2: IONCollection) {
        if collection1.equals(to: collection2) == false {
            // call change blocks
            ION.callUpdateBlocks(collection1.identifier)
        }
    }

    /// Init is private because only class functions should be used
    fileprivate init() {}
}
