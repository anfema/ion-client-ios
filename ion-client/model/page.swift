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
    
    /// Page identifier
    public var identifier: String
    
    /// Page parent identifier
    public var parent: String?
    
    /// Collection of this page
    public var collection: IONCollection
    
    /// Last update date of this page
    public var lastUpdate: NSDate?
    
    /// This instance produced an error while fetching from net
    public var hasFailed = false
    
    /// Locale code for the page
    public var locale: String
    
    /// Layout identifier (name of the toplevel container outlet)
    public var layout: String
    
    /// Content list
    public var content = [IONContent]()
    
    /// Page position
    public var position: Int = 0
    
    /// Set to true to avoid fetching from cache
    private var useCache = IONCacheBehaviour.Prefer
    
    /// Page has loaded
    internal var isReady = false
    
    /// Internal lock
    internal var parentLock = NSLock()
    
    /// Work queue
    internal var workQueue: dispatch_queue_t
    
    /// Internal uuid
    internal var uuid = NSUUID().UUIDString
    
    /// Internal identifier used to store the page into the `collection.pageCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()
    
    
    // MARK: Initializer
    
    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `IONCollection`
    ///
    /// - parameter collection: The collection this page belongs to
    /// - parameter identifier: The page identifier
    /// - parameter layout: The page layout
    /// - parameter useCache: `.Prefer`: Loads the page from cache if no update is available.
    ///                       `.Force`:  Loads the page from cache.
    ///                       `.Ignore`: Loads the page from server.
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides Result.Success containing an `IONPage` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    init(collection: IONCollection, identifier: String, layout: String?, useCache: IONCacheBehaviour, parent: String?, callback: (Result<IONPage, IONError> -> Void)?) {
        // Full asynchronous initializer, self will be populated asynchronously
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.ion.page.\(identifier)", DISPATCH_QUEUE_SERIAL)
        self.layout = layout ?? "unknown"
        self.collection = collection
        self.useCache = useCache
        self.parent = parent
        self.locale = self.collection.locale
        
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
    /// - parameter callback: Callback to call
    public func waitUntilReady(callback: (Result<IONPage, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
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
        dispatch_barrier_async(workQueue) {
            responseQueueCallback(callback, parameter: (page: self, completed: !self.hasFailed))
        }
        
        return self
    }
    
    
    /// Fetch an outlet by name (from loaded page)
    ///
    /// - parameter name: Outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - returns: Result.Success containing an `IONContent` if the outlet is valid
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
    public func outlet(name: String, position: Int = 0) -> Result<IONContent, IONError> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a page loading asynchronously
            return .Failure(.DidFail)
        }
        
        // search for content with the named outlet and specified position
        guard let cObj = self.content.filter({ $0.outlet == name && $0.position == position }).first else {
            return .Failure(.OutletNotFound(name))
        }
        
        return .Success(cObj)
    }
    
    
    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - parameter name: Outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the outlet becomes available.
    ///                       Provides `Result.Success` containing an `IONContent` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: `self` to be able to chain another call
    public func outlet(name: String, position: Int = 0, callback: (Result<IONContent, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.outlet(name, position: position))
        }
        
        return self
    }
    
    
    /// Check if an Outlet exists
    ///
    /// - parameter name: Outlet to check
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `Bool` if the page becomes available
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func outletExists(name: String, position: Int = 0) -> Result<Bool, IONError> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a page loading asynchronously
            return .Failure(.DidFail)
        }
        
        // search first occurrence of content with the named outlet and specified position
        for content in self.content where content.outlet == name {
            if content.position == position {
                return .Success(true)
            }
        }
        
        return .Success(false)
    }
    
    
    /// Check if an Outlet exists
    ///
    /// - parameter name: Outlet to check
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides `Result.Success` containing a `Bool` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: `self` for chaining
    public func outletExists(name: String, position: Int = 0, callback: (Result<Bool, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.outletExists(name, position: position))
        }
        
        return self
    }

    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name:     outlet to check
    /// - parameter callback: callback with object count
    ///
    /// - returns: `self` for chaining
    public func numberOfContentsForOutlet(name: String, callback: (Result<Int, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.numberOfContentsForOutlet(name))
        }
        
        return self
    }
    
    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name: outlet to check
    ///
    /// - returns: count if page was ready, `nil` if page is not loaded
    public func numberOfContentsForOutlet(name: String) -> Result<Int, IONError> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a async loading page
            return .Failure(.DidFail)
        }
        
        // search content
        return .Success(self.content.filter({ $0.outlet == name }).count)
    }
    
    // MARK: Private
    
    private init(forkedWorkQueueWithCollection collection: IONCollection, identifier: String, locale: String) {
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.ion.page.\(identifier).fork.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        self.locale = locale
        self.useCache = .Prefer
        self.collection = collection
        self.layout = ""
        
        // FIXME: How to remove this from the collection cache again?
        self.collection.pageCache[self.forkedIdentifier] = self
    }
    
    
    /// Fetch page from cache or web
    ///
    /// - parameter identifier: Page identifier to get
    /// - parameter callback: Block to call when the fetch finished
    private func fetch(identifier: String, callback: (IONError? -> Void)) {
        IONRequest.fetchJSON("\(self.collection.locale)/\(self.collection.identifier)/\(identifier)", queryParameters: ["variation": ION.config.variation ], cached: ION.config.cacheBehaviour(self.useCache)) { result in
            
            guard case .Success(let resultValue) = result else {
                if let error = result.error, case .NotAuthorized = error {
                    callback(error)
                } else {
                    callback(.PageNotFound(identifier))
                }

                return nil
            }
            
            // We need a result value and need it to be a dictionary
            guard case .JSONDictionary(let dict) = resultValue else {
                callback(.JSONObjectExpected(resultValue))
                return nil
            }
            
            // Furthermore we need a page and a last_updated element
            guard let rawPage = dict["page"] where dict["last_updated"] != nil,
                case .JSONArray(let array) = rawPage else {
                    callback(.JSONObjectExpected(dict["page"]))
                    return nil
            }
            
            // If we have a nonzero result
            if let firstElement = array.first, case .JSONDictionary(let dict) = firstElement {
                // Make sure everything is there
                guard let rawIdentifier     = dict["identifier"],
                    let rawContents         = dict["contents"],
                    let rawLastChanged      = dict["last_changed"],
                    let parent              = dict["parent"],
                    let rawLocale           = dict["locale"],
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
                
                // Parse and append content to this page
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
            
            // Reset to using cache
            self.useCache = .Prefer
            
            // All finished, call block
            callback(nil)
            
            return self.lastUpdate
        }
    }
    
    
    /// Recursively append all content
    ///
    /// - parameter obj: The content object to append including it's children
    private func appendContent(obj: IONContent) {
        self.content.append(obj)
        
        guard case let container as IONContainerContent = obj else {
            return
        }
        
        // Append all toplevel content
        for child in container.children {
            // Container's children are appended on base level to be able to find them quicker
            self.content.append(child)
        }
    }
}

/// Cancelable page, either finish processing with `finish()` or cancel with `cancel()`. Will leak if not done so.
public class CancelableIONPage: IONPage {
    
    init(page: IONPage) {
        super.init(forkedWorkQueueWithCollection: page.collection, identifier: page.identifier, locale: page.locale)
        
        // Dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
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