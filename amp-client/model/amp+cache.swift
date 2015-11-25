//
//  amp+cache.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

extension AMP {
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
    /// - parameter host: a hostname to empty the cache for
    public class func resetDiskCache(host host:String) {
        // TODO: Write test for resetDiskCache(host:)
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(host)
    }
    
    /// Clear disk cache for specific host and locale
    ///
    /// Removes all cached requests and files for the specified server, does not affect memory cache so be careful
    /// - parameter host: a hostname to empty the cache for
    /// - parameter locale: the locale to reset
    public class func resetDiskCache(host host:String, locale:String) {
        // TODO: Write test for resetDiskCache(host:locale:)
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(host, locale:locale)
    }
    
    /// Clear disk cache for specific locale and all hosts
    ///
    /// Removes all cached requests and files for the specified locale and all servers, does not affect memory cache so be careful
    /// - parameter locale: a locale code to empty the cache for
    public class func resetDiskCache(locale locale: String) {
        // TODO: Write test for resetDiskCache(locale:)
        self.config.lastOnlineUpdate = nil
        AMPRequest.resetCache(locale: locale)
    }
    
    /// Determine if collection cache has timed out
    ///
    /// - returns: true if cache is old
    internal class func hasCacheTimedOut() -> Bool {
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

}