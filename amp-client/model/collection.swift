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
    
    /// last change date on server
    public var lastChanged:NSDate?

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
    private var useCache = AMPCacheBehaviour.Prefer
    
    /// block to call on completion
    private var completionBlock: ((collection: Result<AMPCollection, AMPError>, completed: Bool) -> Void)?
    
    /// archive download url
    internal var archiveURL:String!
    
    /// FTS download url
    internal var ftsDownloadURL:String?

    /// internal id
    internal var uuid = NSUUID().UUIDString
    
    /// internal identifier used to store the collection into the `AMP.collectionCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()
    
    
    // MARK: - Initializer
    
    /// Initialize collection async
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// - parameter identifier: the collection identifier
    /// - parameter locale: locale code to fetch
    /// - parameter useCache: set to false to force a refresh
    /// - parameter callback: block to call when collection is fully loaded
    init(identifier: String, locale: String, useCache: AMPCacheBehaviour, callback:(Result<AMPCollection, AMPError> -> Void)?) {
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        
        self.workQueue = dispatch_queue_create("com.anfema.amp.collection.\(identifier)", DISPATCH_QUEUE_SERIAL)
        
        func performCallback(result: Result<AMPCollection, AMPError>) {
            guard let callback = callback else {
                return
            }
            
            dispatch_async(AMP.config.responseQueue) {
                callback(result)
                dispatch_barrier_async(self.workQueue) {
                    self.checkCompleted()
                }
            }
        }
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            self.parentLock.lock()
            let semaphore = dispatch_semaphore_create(0)
            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    performCallback(.Failure(error))
                    self.hasFailed = true
                } else {
                    AMP.collectionCache[identifier] = self
                    performCallback(.Success(self))
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.parentLock.unlock()
        }
    }
   
    // MARK: - API
    
    /// Fetch a page from this collection
    ///
    /// - parameter identifier: page identifier
    /// - parameter callback: the callback to call when the page becomes available
    /// - returns: self, to be able to chain more actions to the collection
    public func page(identifier: String, callback:(Result<AMPPage, AMPError> -> Void)) -> AMPCollection {
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
                    self.pageCache[identifier] = AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: .Ignore, parent:meta.parent) { page in
                        page.position = meta.position
                        callback(.Success(page))
                        page.onCompletion { _,_ in
                            self.checkCompleted()
                        }
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
                            callback(.Success(page))
                            self.checkCompleted()
                        }
                    }
                } else {
                    dispatch_async(page.workQueue) {
                        guard !self.hasFailed else {
                            return
                        }
                        if checkNeedsUpdate() {
                            updateBlock()
                        } else {
                            dispatch_async(AMP.config.responseQueue) {
                                callback(.Success(page))
                                self.checkCompleted()
                            }
                        }
                    }
                }
            } else {
                guard let meta = self.getPageMetaForPage(identifier) else {
                    callback(.Failure(.PageNotFound(identifier)))
                    return
                }
                self.pageCache[identifier] = AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: .Prefer, parent:meta.parent) { page in
                    page.position = meta.position
                    
                    // recursive call to use update check from "page is caches" path
                    self.page(identifier) { page in
                        callback(page)
                    }
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
            let page = AMPPage(collection: self, identifier: identifier, layout: layout, useCache: .Prefer, parent: parent) { page in
                dispatch_async(self.workQueue) {
                    self.checkCompleted()
                }
            }
            page.position = position
            self.pageCache[identifier] = page
            return page
        }
    }
    
    
    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves async once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter index: position of the page in the collection
    /// - returns: a page that resolves automatically if the underlying page becomes available, nil if page unknown
    public func page(index: Int) -> AMPPage? {
        guard index > 0 else
        {
            return nil
        }
        
        let pages = self.pageMeta.filter({ $0.parent == nil }).sort({ $0.0.position < $0.1.position })
        
        guard pages.count > 0 && index < pages.count else {
            return nil
        }
        
        return page(pages[index].identifier)
    }
    
  
    /// Enumerate pages
    ///
    /// - parameter callback: block to call for each page
    public func pages(callback: (Result<AMPPage, AMPError> -> Void)) -> AMPCollection {
        // append page listing to work queue
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            
            // only pages where no parent is set will be returned (top level)
            for meta in self.pageMeta where meta.parent == nil {
                self.page(meta.identifier, callback: callback)
            }
        }
        
        return self
    }

    /// Fork the work queue, the returning collection has to be finished or canceled, else you risk a memory leak
    ///
    /// - returns: self with new work queue that is cancelable
    public func cancelable() -> CancelableAMPCollection {
        return CancelableAMPCollection(collection: self)
    }

    // MARK: - Internal
    
    
    /// Callback when collection fully loaded
    ///
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func waitUntilReady(callback: (Result<AMPCollection, AMPError> -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                callback(.Failure(AMPError.DidFail))
                return
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(.Success(self))
            }
        }
        
        return self
    }

    /// Callback when collection work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed
    ///
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func onCompletion(callback: ((collection: Result<AMPCollection, AMPError>, completed: Bool) -> Void)) -> AMPCollection {
        dispatch_barrier_async(self.workQueue) {
            self.completionBlock = callback
        }
        
        return self
    }
    
    // MARK: - Private
    
    private func checkCompleted() {
        dispatch_barrier_async(self.workQueue) {
            var completed = true
            for (_, page) in self.pageCache {
                if !page.isReady && !page.hasFailed {
                    completed = false
                    break
                }
            }
            
            if let completionBlock = self.completionBlock where completed == true {
                self.completionBlock = nil
                dispatch_async(AMP.config.responseQueue) {
                    completionBlock(collection: .Success(self), completed: !self.hasFailed)
                }
            }
        }
    }
    
    private init(forkedWorkQueueWithIdentifier identifier: String, locale: String) {
        self.locale = locale
        self.useCache = .Prefer
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.amp.collection.\(identifier).forked.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        AMP.collectionCache[self.forkedIdentifier] = self
    }

    /// Fetch collection from cache or web
    ///
    /// - parameter identifier: collection identifier to get
    /// - parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(AMPError? -> Void)) {
        AMPRequest.fetchJSON("\(self.locale)/\(identifier)", queryParameters: [ "variation" : AMP.config.variation ], cached:self.useCache) { result in
            if case .Failure(let error) = result {
                if case .NotAuthorized = error {
                    callback(error)
                } else {
                    callback(AMPError.CollectionNotFound(identifier))
                }
                return
            }
            
            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    callback(AMPError.JSONObjectExpected(result.value!))
                    return
            }
            
            // furthermore we need a collection and a last_updated element
            guard let rawCollection = dict["collection"], rawLastUpdated = dict["last_updated"],
                  case .JSONArray(let array)      = rawCollection,
                  case .JSONNumber(let timestamp) = rawLastUpdated else {
                    callback(AMPError.JSONObjectExpected(result.value!))
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {
                
                // make sure everything is there
                guard let rawIdentifier = dict["identifier"], rawPages = dict["pages"], rawDefaultLocale = dict["default_locale"],
                    rawArchive = dict["archive"], rawFTSdb = dict["fts_db"],
                      case .JSONString(let id)             = rawIdentifier,
                      case .JSONString(let defaultLocale)  = rawDefaultLocale,
                      case .JSONString(let archiveURL)     = rawArchive,
                      case .JSONArray(let pages)           = rawPages else {
                        callback(AMPError.InvalidJSON(result.value!))
                        return
                }
            
                // initialize self
                self.identifier = id
                self.defaultLocale = defaultLocale
                self.archiveURL = archiveURL
                if case .JSONString(let ftsURL) = rawFTSdb {
                    self.ftsDownloadURL = ftsURL
                }
                
                // extract last change date from collection, default to last update when not available
                self.lastChanged = self.lastUpdate
                if let rawLastChanged = dict["last_changed"] {
                    if case .JSONString(let lastChanged) = rawLastChanged {
                        self.lastChanged = NSDate(isoDateString: lastChanged)
                    }
                }
                            
                // initialize page metadata objects from the collection's page array
                for page in pages {
                    do {
                        let obj = try AMPPageMeta(json: page, position: 0, collection: self)

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
                            if AMP.config.loggingEnabled {
                                print("Invalid page: " + json)
                            }
                        } else {
                            if AMP.config.loggingEnabled {
                                print("Invalid page, invalid json")
                            }
                        }
                    }
                }
            }
            
            // revert to using cache
            self.useCache = .Prefer
            
            // all finished, call callback
            callback(nil)
        }
    }
}


public class CancelableAMPCollection: AMPCollection {
    
    init(collection: AMPCollection) {
        super.init(forkedWorkQueueWithIdentifier: collection.identifier, locale: collection.locale)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            collection.parentLock.lock()
            self.identifier = collection.identifier
            self.locale = collection.locale
            self.defaultLocale = collection.defaultLocale
            self.lastUpdate = collection.lastUpdate
            self.pageMeta = collection.pageMeta
            self.hasFailed = collection.hasFailed
            collection.parentLock.unlock()
            self.checkCompleted()
        }
    }
    
    public func cancel() {
        dispatch_barrier_async(self.workQueue) {
            // cancel all page loads
            
            // TODO: Test cancelling of page loads, needs support in mock framework
            for (_, page) in self.pageCache {
                if case let p as CancelableAMPPage = page {
                    p.cancel()
                }
            }
            // set ourselves to failed to cancel all queued items
            self.hasFailed = true
        
            // remove self from cache
            self.finish()
        }
    }
    
    public func finish() {
        dispatch_barrier_async(self.workQueue) {
            self.pageCache.removeAll() // break cycle
            AMP.collectionCache.removeValueForKey(self.forkedIdentifier)
        }
    }
}