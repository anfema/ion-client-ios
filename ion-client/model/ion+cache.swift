//
//  ion+cache.swift
//  ion-client
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation

extension ION {
    /// Clear memory cache
    ///
    /// Call in cases of memory warnings to purge the memory cache, calls to cached objects will punch through to disk
    /// cache and have a parsing and initialization penalty on next call.
    ///
    public class func resetMemCache() {
        for collection in self.collectionCache.keys {
            resetMemCache(forCollection: collection)
        }
    }

    /// Clear memory cache for a specific collection
    ///
    /// Call in cases of memory warnings to purge the memory cache, calls to cached objects will punch through to disk
    /// cache and have a parsing and initialization penalty on next call.
    ///
    /// - parameter collectionIdentifier: Collection to clear
    ///
    public class func resetMemCache(forCollection collectionIdentifier: String) {
        self.collectionCache[collectionIdentifier]?.pageCache.removeAll()
        self.collectionCache.removeValue(forKey: collectionIdentifier)
    }

    /// Clear disk cache
    ///
    /// Removes all cached requests and files for the configured server, does not affect memory cache so be careful
    ///
    public class func resetDiskCache() {
        self.config.lastOnlineUpdate.removeAll()
        for (_, collection) in self.collectionCache {
            collection.lastCompleteUpdate = nil
        }
        IONRequest.resetCache(forLocale: self.config.locale)
    }

    /// Clear disk cache for specific locale and all hosts
    ///
    /// Removes all cached requests and files for the specified locale and all servers, does not affect memory cache so be careful
    ///
    /// - parameter locale: a locale code to empty the cache for
    ///
    public class func resetDiskCache(forLocale locale: String) {
        self.config.lastOnlineUpdate.removeAll()
        let prefs = UserDefaults.standard
        prefs.removeObject(forKey: "ION.collection.lastUpdated")
        prefs.synchronize()
        IONRequest.resetCache(forLocale: locale)
    }

    /// Determine if collection cache has timed out
    ///
    /// - parameter collectionIdentifier: The identifier of the `IONCollection` that should be tested if timed out.
    ///
    /// - returns: true if cache is old
    ///
    internal class func hasCacheTimedOut(collection collectionIdentifier: String) -> Bool {
        var timeout = false
        if let lastUpdate = self.config.lastOnlineUpdate[collectionIdentifier] {
            let currentDate = Date()
            if lastUpdate.addingTimeInterval(self.config.caching.cacheTimeout).compare(currentDate) == ComparisonResult.orderedAscending {
                timeout = true
            }
        } else {
            timeout = true
        }
        return timeout
    }

}
