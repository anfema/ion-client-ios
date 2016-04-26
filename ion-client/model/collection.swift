//
//  collection.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

/// Collection class, contains pages, has functionality to asynchronously fetch data
public class IONCollection {
    
    /// identifier
    public var identifier:String
    
    /// locale code
    public var locale:String
    
    /// default locale for this collection
    public var defaultLocale:String?
    
    /// last update date
    public var lastUpdate:NSDate?
    
    /// last change date on server
    public var lastChanged:NSDate?
    
    /// this instance produced an error while fetching from net
    public var hasFailed: Bool = false
    
    /// page metadata
    internal var pageMeta = [IONPageMeta]()
    
    /// memory cache for pages
    internal var pageCache = [String: IONPage]()
    
    /// internal lock
    internal var parentLock = NSLock()
    
    /// work queue
    internal var workQueue: dispatch_queue_t
    
    /// set to false to avoid using the cache (refreshes, etc.)
    private var useCache = IONCacheBehaviour.Prefer
    
    /// block to call on completion
    private var completionBlock: ((collection: Result<IONCollection, IONError>, completed: Bool) -> Void)?
    
    /// archive download url
    internal var archiveURL:String?
    
    /// FTS download url
    internal var ftsDownloadURL:String?
    
    /// internal id
    internal var uuid = NSUUID().UUIDString
    
    /// internal identifier used to store the collection into the `ION.collectionCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()
    
    
    // MARK: - Initializer
    
    /// Initialize collection async
    ///
    /// use `collection` method of `ION` class instead!
    ///
    /// - parameter identifier: the collection identifier
    /// - parameter locale: locale code to fetch
    /// - parameter useCache: set to false to force a refresh
    /// - parameter callback: block to call when collection is fully loaded
    init(identifier: String, locale: String, useCache: IONCacheBehaviour, callback:(Result<IONCollection, IONError> -> Void)?) {
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        
        self.workQueue = dispatch_queue_create("com.anfema.ion.collection.\(identifier)", DISPATCH_QUEUE_SERIAL)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            self.parentLock.lock()
            let semaphore = dispatch_semaphore_create(0)
            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    responseQueueCallback(callback, parameter: .Failure(error))
                    self.hasFailed = true
                } else {
                    ION.collectionCache[identifier] = self
                    responseQueueCallback(callback, parameter:.Success(self))
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
    public func page(identifier: String, callback:(Result<IONPage, IONError> -> Void)) -> IONCollection {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            if let page = self.pageCache[identifier] {
                
                if page.isReady {
                    if self.checkNeedsUpdate(page) {
                        self.update(page, callback: callback)
                    } else {
                        dispatch_async(ION.config.responseQueue) {
                            callback(.Success(page))
                            dispatch_barrier_async(self.workQueue) {
                                self.checkCompleted()
                            }
                        }
                    }
                } else {
                    dispatch_async(page.workQueue) {
                        guard !self.hasFailed else {
                            return
                        }
                        if self.checkNeedsUpdate(page) {
                            self.update(page, callback: callback)
                        } else {
                            dispatch_async(ION.config.responseQueue) {
                                callback(.Success(page))
                                dispatch_barrier_async(self.workQueue) {
                                    self.checkCompleted()
                                }
                            }
                        }
                    }
                }
            } else {
                guard let meta = self.getPageMetaForPage(identifier) else {
                    responseQueueCallback(callback, parameter: .Failure(.PageNotFound(identifier)))
                    return
                }
                self.pageCache[identifier] = IONPage(collection: self, identifier: identifier, layout: meta.layout, useCache: .Prefer, parent:meta.parent) { result in
                    guard case .Success(let page) = result else {
                        // FIXME: What happens in error case?
                        return
                    }
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
    /// As there is no callback, this returns a page that resolves asynchronously once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter identifier: page identifier
    /// - returns: a page that resolves automatically if the underlying page becomes available, nil if page unknown
    public func page(identifier: String) -> IONPage {
        
        if let page = self.pageCache[identifier] {
            // well page is cached, just return cached version
            if page.isReady {
                if self.checkNeedsUpdate(page) {
                    return self.update(page, callback: nil) ?? page
                } else {
                    return page
                }
            }
        }
        
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
        let page = IONPage(collection: self, identifier: identifier, layout: layout, useCache: .Prefer, parent: parent) { page in
            dispatch_barrier_async(self.workQueue) {
                self.checkCompleted()
            }
        }
        page.position = position
        self.pageCache[identifier] = page
        return page
    }
    
    
    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves asynchronously once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter index: position of the page in the collection
    /// - returns: a page that resolves automatically if the underlying page becomes available, nil if page unknown
    public func page(index: Int) -> IONPage? {
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
    public func pages(callback: (Result<IONPage, IONError> -> Void)) -> IONCollection {
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
    public func cancelable() -> CancelableIONCollection {
        return CancelableIONCollection(collection: self)
    }
    
    // MARK: - Internal
    
    
    /// Callback when collection fully loaded
    ///
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func waitUntilReady(callback: (Result<IONCollection, IONError> -> Void)) -> IONCollection {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            responseQueueCallback(callback, parameter: .Success(self))
        }
        
        return self
    }
    
    /// Callback when collection work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed, the callback will only be called if the collection fetches any page,
    /// it will not fire when no other actions than loading the collection itself occur.
    ///
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func onCompletion(callback: ((collection: Result<IONCollection, IONError>, completed: Bool) -> Void)) -> IONCollection {
        dispatch_barrier_async(self.workQueue) {
            self.completionBlock = callback
        }
        
        return self
    }
    
    // MARK: - Private
    
    private func checkNeedsUpdate(page: IONPage) -> Bool {
        // ready, check if we need to update
        if page.hasFailed {
            return true
        } else {
            if let meta = self.getPageMetaForPage(page.identifier) {
                if let lastUpdate = page.lastUpdate where lastUpdate.compare(meta.lastChanged) == NSComparisonResult.OrderedAscending {
                    // page out of date, force update
                    return true
                }
            }
        }
        return false
    }
    
    private func update(page: IONPage, callback:(Result<IONPage, IONError> -> Void)?) -> IONPage? {
        // fetch page update
        guard let meta = self.getPageMetaForPage(page.identifier) else {
            return nil
        }
        self.pageCache[identifier] = IONPage(collection: self, identifier: page.identifier, layout: meta.layout, useCache: .Ignore, parent:meta.parent) { result in
            guard case .Success(let page) = result else {
                // FIXME: what happens in the error case?
                return
            }
            page.position = meta.position
            if let callback = callback {
                responseQueueCallback(callback, parameter: .Success(page))
            }
            page.onCompletion { _,_ in
                self.checkCompleted()
            }
        }
        return self.pageCache[identifier]
    }
    
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
                dispatch_async(ION.config.responseQueue) {
                    completionBlock(collection: .Success(self), completed: !self.hasFailed)
                }
            }
        }
    }
    
    private init(forkedWorkQueueWithIdentifier identifier: String, locale: String) {
        self.locale = locale
        self.useCache = .Prefer
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.ion.collection.\(identifier).forked.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        ION.collectionCache[self.forkedIdentifier] = self
    }
    
    /// Fetch collection from cache or web
    ///
    /// - parameter identifier: collection identifier to get
    /// - parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(IONError? -> Void)) {
        IONRequest.fetchJSON("\(self.locale)/\(identifier)", queryParameters: ["variation" : ION.config.variation ], cached:self.useCache) { result in
            
            guard case .Success(let resultValue) = result else {
                if let error = result.error, case .NotAuthorized = error {
                    callback(error)
                } else {
                    callback(.CollectionNotFound(identifier))
                }
                
                return nil
            }
            
            // we need a result value and need it to be a dictionary
            guard case .JSONDictionary(let dict) = resultValue else {
                callback(.JSONObjectExpected(resultValue))
                return nil
            }
            
            // furthermore we need a collection and a last_updated element
            guard let rawCollection = dict["collection"], rawLastUpdated = dict["last_updated"],
                case .JSONArray(let array)      = rawCollection,
                case .JSONNumber(let timestamp) = rawLastUpdated else {
                    callback(.JSONObjectExpected(resultValue))
                    return nil
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
                        callback(.InvalidJSON(resultValue))
                        return nil
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
                        self.lastChanged = NSDate(ISODateString: lastChanged)
                        self.lastUpdate = self.lastChanged
                    }
                }
                
                // initialize page metadata objects from the collection's page array
                for page in pages {
                    do {
                        let obj = try IONPageMeta(json: page, position: 0, collection: self)
                        
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
                            if ION.config.loggingEnabled {
                                print("Invalid page: " + json)
                            }
                        } else {
                            if ION.config.loggingEnabled {
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
            
            return self.lastChanged
        }
    }
}


extension IONCollection {
    
    /// Checks if the collection and 'otherCollection' have the same content.
    ///
    /// -parameter otherCollection: The collection you want to check for equal content.
    /// -returns: true if both collections have the same content - false if they have different content.
    public func equals(otherCollection: IONCollection) -> Bool {
        var collectionChanged = false
        
        // compare metadata count
        if (self.pageMeta.count != otherCollection.pageMeta.count) || (self.lastChanged != otherCollection.lastChanged) {
            collectionChanged = true
        } else {
            // compare old collection and new collection page change dates and identifiers
            for i in 0..<self.pageMeta.count {
                let c1 = self.pageMeta[i]
                let c2 = otherCollection.pageMeta[i]
                if c1.identifier != c2.identifier || c1.lastChanged.compare(c2.lastChanged) != .OrderedSame {
                    collectionChanged = true
                    break
                }
            }
        }
        
        return collectionChanged == false
    }
}


public class CancelableIONCollection: IONCollection {
    
    init(collection: IONCollection) {
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
                if case let p as CancelableIONPage = page {
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
            ION.collectionCache.removeValueForKey(self.forkedIdentifier)
        }
    }
}