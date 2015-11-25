//
//  collection.swift
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
import DEjson

/// Collection class, contains pages, has functionality to async fetch data
public class AMPCollection {
    
    /// identifier
    public var identifier:String!
    
    /// locale code
    public var locale:String!

    /// default locale for this collection
    public var defaultLocale:String?
    
    /// last update date
    public var lastUpdate:NSDate?

    /// this instance produced an error while fetching from net
    public var hasFailed: Bool = false

    /// page metadata
    internal var pageMeta = [AMPPageMeta]()

    /// memory cache for pages
    internal var pageCache = [String:AMPPage]()

    /// internal lock for errorhandler
    internal var parentLock = NSLock()

    /// work queue
    internal var workQueue: dispatch_queue_t

    /// set to false to avoid using the cache (refreshes, etc.)
    private var useCache = true
    

    // MARK: - Initializer
    
    /// Initialize collection async
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// - parameter identifier: the collection identifier
    /// - parameter locale: locale code to fetch
    /// - parameter useCache: set to false to force a refresh
    /// - parameter callback: block to call when collection is fully loaded
    init(identifier: String, locale: String, useCache: Bool, callback:(AMPCollection -> Void)?) {
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        
        self.workQueue = dispatch_queue_create("com.anfema.amp.collection.\(identifier)", DISPATCH_QUEUE_SERIAL)
       
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            self.parentLock.lock()
            let semaphore = dispatch_semaphore_create(0)
            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    self.callErrorHandler(error)
                    self.hasFailed = true
                } else if let cb = callback {
                    dispatch_async(AMP.config.responseQueue) {
                        cb(self)
                    }
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.parentLock.unlock()
        }
        
        AMP.collectionCache[identifier] = self
    }
   
    // MARK: - API
    
    /// Fetch a page from this collection
    ///
    /// - parameter identifier: page identifier
    /// - parameter callback: the callback to call when the page becomes available
    /// - returns: self, to be able to chain more actions to the collection
    public func page(identifier: String, callback:(AMPPage -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            if let page = self.pageCache[identifier] {
                let updateBlock:(Void -> Void) = {
                    // fetch page update
                    guard let meta = self.getPageMetaForPage(identifier) else {
                        return
                    }
                    self.pageCache[identifier] = AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: true, parent:meta.parent) { page in
                        page.position = meta.position
                        callback(page)
                    }
                }
                
                let checkNeedsUpdate:(Void -> Bool) = {
                    // ready, check if we need to update
                    if page.hasFailed {
                        return true
                    } else {
                        if let meta = self.getPageMetaForPage(page.identifier) {
                            if page.lastUpdate.compare(meta.lastChanged) == NSComparisonResult.OrderedAscending {
                                // page out of date, force update
                                return true
                            }
                        }
                    }
                    return false
                    
                }
                
                if page.isReady {
                    if checkNeedsUpdate() {
                        updateBlock()
                    } else {
                        dispatch_async(AMP.config.responseQueue) {
                            callback(page)
                        }
                    }
                } else {
                    dispatch_async(page.workQueue) {
                        if checkNeedsUpdate() {
                            updateBlock()
                        } else {
                            dispatch_async(AMP.config.responseQueue) {
                                callback(page)
                            }
                        }
                    }
                }
            } else {
                guard let meta = self.getPageMetaForPage(identifier) else {
                    self.callErrorHandler(.PageNotFound(identifier))
                    return
                }
                self.pageCache[identifier] = AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: true, parent:meta.parent) { page in
                    page.position = meta.position
                    callback(page)
                }
            }
        }
        
        // allow further chaining
        return self
    }

    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves async once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter identifier: page identifier
    /// - returns: a page that resolves automatically if the underlying page becomes available, nil if page unknown
    public func page(identifier: String) -> AMPPage {
        // fetch page and resume processing when ready
        var fetch = true
        
        if let page = self.pageCache[identifier] {
            // well page is cached, just return cached version
            if page.isReady {
                fetch = false
                return page
            }
        }
        
        if fetch {
            // search metadata
            var layout: String? = nil
            var parent: String? = nil
            var position: Int = 0
            if let meta = self.getPageMetaForPage(identifier) {
                layout = meta.layout
                parent = meta.parent
                position = meta.position
            }
            
            // not cached, fetch from web and add it to the cache
            let page = AMPPage(collection: self, identifier: identifier, layout: layout, useCache: true, parent: parent) { page in
            }
            page.position = position
            self.pageCache[identifier] = page
            return page
        }
    }
    
    // TODO: public func page(index: Int) -> AMPPage
  
    /// Enumerate pages
    ///
    /// - parameter callback: block to call for each page
    public func pages(callback: (AMPPage -> Void)) -> AMPCollection {
        // append page listing to work queue
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            for meta in self.pageMeta {
                // only pages where no parent is set will be returned (top level)
                if meta.parent == nil {
                    self.page(meta.identifier, callback:callback)
                }
            }
        }
        
        return self
    }
    
    /// Error handler to chain to the collection
    ///
    /// - parameter callback: the block to call in case of an error
    /// - returns: self, to be able to chain more actions to the collection
    public func onError(callback: (AMPError -> Void)) -> AMPCollection {
        return ErrorHandlingAMPCollection(collection: self, errorHandler: callback)
    }
    
    // MARK: - Internal
    
    /// override default error callback to bubble error up to AMP object
    internal func callErrorHandler(error: AMPError) {
        AMP.callError(self.identifier, error: error)
    }
    
    /// Callback when collection fully loaded
    ///
    /// - parameter callback: callback to call
    public func waitUntilReady(callback: (AMPCollection -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            dispatch_async(AMP.config.responseQueue) {
                callback(self)
            }
        }
        return self
    }

    // MARK: - Private
    
    private init(forErrorHandlerWithIdentifier identifier: String, locale: String) {
        self.locale = locale
        self.useCache = true
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.amp.collection.\(identifier).withErrorHandler.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        AMP.collectionCache[identifier + "-" + NSUUID().UUIDString] = self
    }

    /// Fetch collection from cache or web
    ///
    /// - parameter identifier: collection identifier to get
    /// - parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(AMPError? -> Void)) {
        AMPRequest.fetchJSON("collections/\(identifier)", queryParameters: [ "locale" : self.locale ], cached:self.useCache) { result in
            if case .Failure = result {
                callback(AMPError.CollectionNotFound(identifier))
                return
            }
            
            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    callback(AMPError.JSONObjectExpected(result.value!))
                    return
            }
            
            // furthermore we need a collection and a last_updated element
            guard dict["collection"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["collection"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    callback(AMPError.JSONObjectExpected(result.value!))
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {
                
                // make sure everything is there
                guard (dict["identifier"] != nil) && (dict["pages"] != nil) && (dict["default_locale"] != nil),
                      case .JSONString(let id)    = dict["identifier"]!,
                      case .JSONString(let defaultLocale) = dict["default_locale"]!,
                      case .JSONArray(let pages)          = dict["pages"]! else {
                        callback(AMPError.InvalidJSON(result.value!))
                        return
                }
            
                // initialize self
                self.identifier = id
                self.defaultLocale = defaultLocale
            
                // initialize page metadata objects from the collection's page array
                for page in pages {
                    do {
                        let obj = try AMPPageMeta(json: page, position: 0)

                        // find max position for current parent
                        var position = -1
                        for page in self.pageMeta {
                            if page.parent == obj.parent && page.position > position {
                                position = page.position
                            }
                        }
                        obj.position = position + 1

                        self.pageMeta.append(obj)
                    } catch {
                        if let json = JSONEncoder(page).prettyJSONString {
                            print("Invalid page: " + json)
                        } else {
                            print("Invalid page, invalid json")
                        }
                    }
                }
            }
            
            // revert to using cache
            self.useCache = true
            
            // all finished, call callback
            callback(nil)
        }
    }
 }



class ErrorHandlingAMPCollection: AMPCollection {
    private var errorHandler: (AMPError -> Void)
    
    init(collection: AMPCollection, errorHandler: (AMPError -> Void)) {
        self.errorHandler = errorHandler
        super.init(forErrorHandlerWithIdentifier: collection.identifier, locale: collection.locale)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            collection.parentLock.lock()
            self.identifier = collection.identifier
            self.locale = collection.locale
            self.defaultLocale = collection.defaultLocale
            self.lastUpdate = collection.lastUpdate
            self.pageMeta = collection.pageMeta
            collection.parentLock.unlock()
        }

    }
    
    /// override default error callback to bubble error up to AMP object
    override internal func callErrorHandler(error: AMPError) {
       errorHandler(error)
    }
}
