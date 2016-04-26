//
//  page.swift
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
import iso_rfc822_date

/// Page class, contains functionality to fetch outlet content
public class IONPage {
    
    /// page identifier
    public var identifier:String
    
    /// page parent identifier
    public var parent:String?
    
    /// collection of this page
    public var collection: IONCollection
    
    /// last update date of this page
    public var lastUpdate:NSDate?
    
    /// this instance produced an error while fetching from net
    public var hasFailed = false
    
    /// locale code for the page
    public var locale:String
    
    /// layout identifier (name of the toplevel container outlet)
    public var layout:String
    
    /// content list
    public var content = [IONContent]()
    
    /// page position
    public var position: Int = 0
    
    /// set to true to avoid fetching from cache
    private var useCache = IONCacheBehaviour.Prefer
    
    /// page has loaded
    internal var isReady = false
    
    /// internal lock
    internal var parentLock = NSLock()
    
    /// work queue
    internal var workQueue: dispatch_queue_t
    
    /// internal uuid
    internal var uuid = NSUUID().UUIDString
    
    /// internal identifier used to store the page into the `collection.pageCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()
    
    // MARK: Initializer
    
    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `IONCollection`
    ///
    /// - parameter collection: the collection this page belongs to
    /// - parameter identifier: the page identifier
    /// - parameter layout: the page layout
    /// - parameter useCache: set to false to force a page refresh
    /// - parameter callback: the block to call when initialization finished
    init(collection: IONCollection, identifier: String, layout: String?, useCache: IONCacheBehaviour, parent: String?, callback:(Result<IONPage, IONError> -> Void)?) {
        // Full async initializer, self will be populated async
        self.identifier = identifier
        if let layout = layout {
            self.layout = layout
        } else {
            self.layout = "unknown"
        }
        self.collection = collection
        self.useCache = useCache
        self.parent = parent
        self.locale = self.collection.locale
        
        self.workQueue = dispatch_queue_create("com.anfema.ion.page.\(identifier)", DISPATCH_QUEUE_SERIAL)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            self.parentLock.lock()
            let semaphore = dispatch_semaphore_create(0)
            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    self.hasFailed = true
                    responseQueueCallback(callback, parameter: .Failure(error))
                    dispatch_semaphore_signal(semaphore)
                    
                } else {
                    if self.content.count > 0 {
                        if case let container as IONContainerContent = self.content.first {
                            self.layout = container.outlet
                        }
                    }
                    
                    guard let pageMeta = self.collection.getPageMetaForPage(identifier) else {
                        self.hasFailed = true
                        responseQueueCallback(callback, parameter: .Failure(IONError.PageNotFound(identifier)))
                        dispatch_semaphore_signal(semaphore)
                        return
                    }
                    
                    if let lastUpdate = self.lastUpdate where lastUpdate.compare(pageMeta.lastChanged) != .OrderedSame {
                        self.useCache = .Ignore
                        self.content.removeAll()
                        self.fetch(identifier) { error in
                            if let error = error {
                                self.hasFailed = true
                                responseQueueCallback(callback, parameter: .Failure(error))
                                dispatch_semaphore_signal(semaphore)
                            } else {
                                if self.content.count > 0 {
                                    if case let container as IONContainerContent = self.content.first {
                                        self.layout = container.outlet
                                    }
                                }
                                self.isReady = true
                                responseQueueCallback(callback, parameter: .Success(self))
                                dispatch_semaphore_signal(semaphore)
                            }
                        }
                    } else {
                        self.isReady = true
                        responseQueueCallback(callback, parameter: .Success(self))
                        dispatch_semaphore_signal(semaphore)
                    }
                }
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.parentLock.unlock()
        }
        
        self.collection.pageCache[identifier] = self
    }
    
    // MARK: - API
    
    /// Fork the work queue, the returning page has to be finished or canceled, else you risk a memory leak
    ///
    /// - returns: `self` with new work queue that is cancelable
    public func cancelable() -> CancelableIONPage {
        return CancelableIONPage(page: self)
    }
    
    /// Callback when page fully loaded
    ///
    /// - parameter callback: callback to call
    public func waitUntilReady(callback: (Result<IONPage, IONError> -> Void)) -> IONPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            responseQueueCallback(callback, parameter: .Success(self))
        }
        
        return self
    }
    
    /// Callback when page work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed
    ///
    /// - parameter callback: callback to call
    /// - returns: `self` for chaining
    public func onCompletion(callback: ((page: IONPage, completed: Bool) -> Void)) -> IONPage {
        dispatch_barrier_async(self.workQueue) {
            responseQueueCallback(callback, parameter: (page: self, completed: !self.hasFailed))
        }
        
        return self
    }
    
    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - parameter name: outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: block to execute when outlet was found, will not be called if no such outlet
    ///                       exists or there was any kind of communication error while fetching the page
    /// - returns: `self` to be able to chain another call
    public func outlet(name: String, position: Int = 0, callback: (Result<IONContent, IONError> -> Void)) -> IONPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            // search content
            let cObj = self.content.filter({ obj -> Bool in
                return obj.outlet == name && obj.position == position
            }).first
            
            if let c = cObj {
                responseQueueCallback(callback, parameter: .Success(c))
            } else {
                responseQueueCallback(callback, parameter: .Failure(.OutletNotFound(name)))
            }
        }
        
        return self
    }
    
    /// Fetch an outlet by name (from loaded page)
    ///
    /// - parameter name: outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - returns: content object if page was loaded and outlet exists
    public func outlet(name: String, position: Int = 0) -> Result<IONContent, IONError> {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return .Failure(.DidFail)
        } else {
            // search content
            let cObj = self.content.filter({ obj -> Bool in
                return obj.outlet == name && obj.position == position
            }).first
            
            if let cObj = cObj {
                return .Success(cObj)
            } else {
                return .Failure(.OutletNotFound(name))
            }
        }
    }
    
    /// Check if an Outlet exists
    ///
    /// - parameter name: outlet to check
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: callback to call
    /// - returns: `self` for chaining
    public func outletExists(name: String, position: Int = 0, callback: (Result<Bool, IONError> -> Void)) -> IONPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            // search content
            var found = false
            for content in self.content where content.outlet == name {
                if content.position == position {
                    found = true
                    break
                }
            }
            
            responseQueueCallback(callback, parameter: .Success(found))
        }
        
        return self
    }
    
    
    /// Check if an Outlet exists
    ///
    /// - parameter name: outlet to check
    /// - parameter position: Position in the array (optional)
    /// - returns: `true` if outlet exists else `false`, `nil` if page not loaded
    public func outletExists(name: String, position: Int = 0) -> Result<Bool, IONError> {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return .Failure(.DidFail)
        } else {
            // search content
            for content in self.content where content.outlet == name {
                if content.position == position {
                    return .Success(true)
                }
            }
            
            return .Success(false)
        }
    }
    
    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name:     outlet to check
    /// - parameter callback: callback with object count
    ///
    /// - returns: `self` for chaining
    public func numberOfContentsForOutlet(name: String, callback: (Result<Int, IONError> -> Void)) -> IONPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .Failure(.DidFail))
                return
            }
            
            // search content
            let count = self.content.filter({ $0.outlet == name }).count
            
            responseQueueCallback(callback, parameter: .Success(count))
        }
        
        return self
    }
    
    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name: outlet to check
    ///
    /// - returns: count if page was ready, `nil` if page is not loaded
    public func numberOfContentsForOutlet(name: String) -> Result<Int, IONError> {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return .Failure(.DidFail)
        } else {
            // search content
            return .Success(self.content.filter({ $0.outlet == name }).count)
        }
    }
    
    // MARK: Private
    
    private init(forkedWorkQueueWithCollection collection: IONCollection, identifier: String, locale: String) {
        self.locale = locale
        self.useCache = .Prefer
        self.collection = collection
        self.identifier = identifier
        self.layout = ""
        self.workQueue = dispatch_queue_create("com.anfema.ion.page.\(identifier).fork.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        self.collection.pageCache[self.forkedIdentifier] = self
    }
    
    /// Fetch page from cache or web
    ///
    /// - parameter identifier: page identifier to get
    /// - parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(IONError? -> Void)) {
        IONRequest.fetchJSON("\(self.collection.locale)/\(self.collection.identifier)/\(identifier)", queryParameters: ["variation" : ION.config.variation ], cached: ION.config.cacheBehaviour(self.useCache)) { result in
            
            guard case .Success(let resultValue) = result else {
                if let error = result.error, case .NotAuthorized = error {
                    callback(error)
                } else {
                    callback(.PageNotFound(identifier))
                }

                return nil
            }
            
            // we need a result value and need it to be a dictionary
            guard case .JSONDictionary(let dict) = resultValue else {
                callback(.JSONObjectExpected(resultValue))
                return nil
            }
            
            // furthermore we need a page and a last_updated element
            guard let rawPage = dict["page"] where dict["last_updated"] != nil,
                case .JSONArray(let array) = rawPage else {
                    callback(.JSONObjectExpected(dict["page"]))
                    return nil
            }
            
            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {
                
                // make sure everything is there
                guard let rawIdentifier = dict["identifier"], rawContents = dict["contents"],
                    rawLastChanged = dict["last_changed"], parent = dict["parent"], rawLocale = dict["locale"],
                    case .JSONString(let id) = rawIdentifier,
                    case .JSONArray(let contents) = rawContents,
                    case .JSONString(let last_changed) = rawLastChanged,
                    case .JSONString(let locale) = rawLocale else {
                        callback(.InvalidJSON(resultValue))
                        return nil
                }
                
                if case .JSONString(let parentID) = parent {
                    self.parent = parentID
                } else {
                    self.parent = nil
                }
                self.identifier = id
                self.locale = locale
                self.lastUpdate = NSDate(ISODateString: last_changed)
                
                // parse and append content to this page
                for c in contents {
                    do {
                        let obj = try IONContent.factory(c)
                        self.appendContent(obj)
                    } catch {
                        // Content could not be deserialized, do not add to page
                        if ION.config.loggingEnabled {
                            print("ION: Deserialization failed")
                        }
                    }
                }
            }
            
            // reset to using cache
            self.useCache = .Prefer
            
            // all finished, call block
            callback(nil)
            return self.lastUpdate
        }
    }
    
    /// Recursively append all content
    ///
    /// - parameter obj: the content object to append including it's children
    private func appendContent(obj: IONContent) {
        self.content.append(obj)
        
        // append all toplevel content
        if case let container as IONContainerContent = obj {
            for child in container.children {
                // container's children are appended on base level to be able to find them quicker
                self.content.append(child)
            }
        }
    }
}

/// Cancelable page, either finish processing with `finish()` or cancel with `cancel()`. Will leak if not done so.
public class CancelableIONPage: IONPage {
    
    init(page: IONPage) {
        super.init(forkedWorkQueueWithCollection: page.collection, identifier: page.identifier, locale: page.locale)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            page.parentLock.lock()
            self.identifier = page.identifier
            self.parent = page.parent
            self.locale = page.locale
            self.lastUpdate = page.lastUpdate
            self.layout = page.layout
            self.content = page.content
            self.position = page.position
            self.hasFailed = page.hasFailed
            self.isReady = true
            page.parentLock.unlock()
        }
    }
    
    /// Cancel all pending requests for this page
    public func cancel() {
        dispatch_barrier_async(self.workQueue) {
            self.hasFailed = true
            self.finish()
        }
    }
    
    /// Finish all requests and discard page
    public func finish() {
        dispatch_barrier_async(self.workQueue) {
            self.collection.pageCache.removeValueForKey(self.forkedIdentifier)
        }
    }
}