//
//  page.swift
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


/// Page class, contains functionality to fetch outlet content
public class AMPPage {
    
    /// page identifier
    public var identifier:String
    
    /// page parent identifier
    public var parent:String?
    
    /// collection of this page
    public var collection:AMPCollection
    
    /// last update date of this page
    public var lastUpdate:NSDate!
    
    /// this instance produced an error while fetching from net
    public var hasFailed = false
    
    /// locale code for the page
    public var locale:String

    /// layout identifier (name of the toplevel container outlet)
    public var layout:String
    
    /// content list
    public var content = [AMPContent]()

    /// page position
    public var position: Int = 0
    
    /// page has loaded
    internal var isReady = false

    /// internal lock for errorhandler
    internal var parentLock = NSLock()

    /// work queue
    internal var workQueue: dispatch_queue_t

    /// set to true to avoid fetching from cache
    private var useCache = false
    
    /// internal uuid
    internal var uuid = NSUUID().UUIDString
    
    // MARK: Initializer
    
    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - parameter collection: the collection this page belongs to
    /// - parameter identifier: the page identifier
    /// - parameter layout: the page layout
    /// - parameter useCache: set to false to force a page refresh
    /// - parameter callback: the block to call when initialization finished
    init(collection: AMPCollection, identifier: String, layout: String?, useCache: Bool, parent: String?, callback:(AMPPage -> Void)?) {
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
        
        self.workQueue = dispatch_queue_create("com.anfema.amp.page.\(identifier)", DISPATCH_QUEUE_SERIAL)
        
        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        dispatch_barrier_async(self.workQueue) {
            self.parentLock.lock()
            let semaphore = dispatch_semaphore_create(0)
            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    self.callErrorHandler(error)
                    self.hasFailed = true
                    
                } else {
                    if self.content.count > 0 {
                        if case let container as AMPContainerContent = self.content.first! {
                            self.layout = container.outlet
                        }
                    }

                    self.isReady = true
                    if let cb = callback {
                        dispatch_async(AMP.config.responseQueue) {
                            cb(self)
                        }
                    }
                }
                dispatch_semaphore_signal(semaphore)
            }
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER)
            self.parentLock.unlock()
        }
        
        self.collection.pageCache[identifier] = self
    }

    // MARK: - API
    
    /// Error handler to chain to the page
    ///
    /// - parameter callback: the block to call in case of an error
    /// - returns: self, to be able to chain more actions to the page
    public func onError(callback: (AMPError -> Void)) -> AMPPage {
        return ErrorHandlingAMPPage(page: self, errorHandler: callback)
    }

    /// Fork the work queue, the returning page has to be finished or canceled, else you risk a memory leak
    ///
    /// - returns: self with new work queue that is cancelable
    public func cancelable() -> CancelableAMPPage {
        return CancelableAMPPage(page: self)
    }
    
    /// override default error callback to bubble error up to collection
    internal func callErrorHandler(error: AMPError) {
        self.collection.callErrorHandler(error)
    }
    
    /// Callback when page fully loaded
    ///
    /// - parameter callback: callback to call
    public func waitUntilReady(callback: (AMPPage -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(self)
            }
        }
        return self
    }
    
    /// Callback when page work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed
    ///
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func onCompletion(callback: ((page: AMPPage, completed: Bool) -> Void)) -> AMPPage {
        dispatch_barrier_async(self.workQueue) {
            dispatch_async(AMP.config.responseQueue) {
                callback(page: self, completed: !self.hasFailed)
            }
        }
        return self
    }
    
    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - parameter name: outlet name to fetch
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to execute when outlet was found, will not be called if no such outlet
    ///                       exists or there was any kind of communication error while fetching the page
    /// - returns: self to be able to chain another call
    public func outlet(name: String, position: Int = 0, callback: (AMPContent -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }

            // search content
            var cObj:AMPContent? = nil
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    if count == position {
                        cObj = content
                        break
                    }
                    count += 1
                }
            }
            if let c = cObj {
                dispatch_async(AMP.config.responseQueue) {
                    callback(c)
                }
            } else {
                self.callErrorHandler(.OutletNotFound(name))
            }
        }
        return self
    }
   
    /// Fetch an outlet by name (from loaded page)
    ///
    /// - parameter name: outlet name to fetch
    /// - parameter position: (optional) position in the array
    /// - returns: content object if page was loaded and outlet exists
    public func outlet(name: String, position: Int = 0) -> AMPContent? {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return nil
        } else {
            // search content
            var cObj:AMPContent? = nil
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    if count == position {
                        cObj = content
                        break
                    }
                    count += 1
                }
            }
            if cObj == nil {
                self.callErrorHandler(.OutletNotFound(name))
            }
            return cObj
        }
    }

    /// Check if an Outlet exists
    ///
    /// - parameter name: outlet to check
    /// - parameter position: (optional) position in the array
    /// - parameter callback: callback to call
    /// - returns: self for chaining
    public func outletExists(name: String, position: Int = 0, callback: (Bool -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
       
            // search content
            var found = false
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    if count == position {
                        found = true
                        break
                    }
                    count += 1
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(found)
            }
        }
        return self
    }

    
    /// Check if an Outlet exists
    ///
    /// - parameter name: outlet to check
    /// - parameter position: (optional) position in the array
    /// - returns: true if outlet exists else false, nil if page not loaded
    public func outletExists(name: String, position: Int = 0) -> Bool? {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return nil
        } else {
            // search content
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    if (count == position) {
                        return true
                    }
                    count += 1
                }
            }
            return false
        }
    }
    
    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name:     outlet to check
    /// - parameter callback: callback with object count
    ///
    /// - returns: self for chaining
    public func numberOfContentsForOutlet(name: String, callback: (Int -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            
            // search content
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    count += 1
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(count)
            }
        }
        return self
    }

    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name: outlet to check
    ///
    /// - returns: count if page was ready, nil if page is not loaded
    public func numberOfContentsForOutlet(name: String) -> Int? {
        if !self.isReady || self.hasFailed {
            // cannot return outlet synchronously from a async loading page
            return nil
        } else {
            // search content
            var count = 0
            for content in self.content {
                if content.outlet == name {
                    count += 1
                }
            }
            return count
        }
    }
    
    // MARK: Private
    
    private init(forkedWorkQueueWithCollection collection: AMPCollection, identifier: String, locale: String) {
        self.locale = locale
        self.useCache = true
        self.collection = collection
        self.identifier = identifier
        self.layout = ""
        self.workQueue = dispatch_queue_create("com.anfema.amp.page.\(identifier).fork.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        self.collection.pageCache[identifier + "-" + self.uuid] = self
    }

    /// Fetch page from cache or web
    ///
    /// - parameter identifier: page identifier to get
    /// - parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(AMPError? -> Void)) {
        AMPRequest.fetchJSON("pages/\(self.collection.identifier)/\(identifier)", queryParameters: [ "locale" : self.collection.locale, "variation" : AMP.config.variation ], cached:self.useCache) { result in
            if case .Failure(let error) = result {
                if case .NotAuthorized = error {
                    callback(error)
                } else {
                    callback(.PageNotFound(identifier))
                }
                return
            }

            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    callback(.JSONObjectExpected(result.value!))
                    return
            }
            
            // furthermore we need a page and a last_updated element
            guard let rawPage = dict["page"] where dict["last_updated"] != nil,
                  case .JSONArray(let array) = rawPage else {
                    callback(.JSONObjectExpected(dict["page"]))
                    return
            }

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {

                // make sure everything is there
                guard let rawIdentifier = dict["identifier"], rawTranslations = dict["translations"],
                    rawLastChanged = dict["last_changed"], let parent = dict["parent"],
                      case .JSONString(let id) = rawIdentifier,
                      case .JSONArray(let translations) = rawTranslations,
                      case .JSONString(let last_changed) = rawLastChanged else {
                        callback(.InvalidJSON(result.value))
                        return
                }
                
                if case .JSONString(let parentID) = parent {
                    self.parent = parentID
                } else {
                    self.parent = nil
                }
                self.identifier = id
                self.lastUpdate = NSDate(isoDateString: last_changed)

                // we only process the first translation as we used the `locale` filter in the request
                if translations.count > 0 {
                    let translation = translations[0]
                    
                    // guard against garbage data
                    guard case .JSONDictionary(let t) = translation else {
                        callback(.JSONObjectExpected(translation))
                        return
                    }
                    
                    // make sure the translation contains all needed fields
                    guard let rawLocale = t["locale"], rawContent = t["content"],
                        case .JSONString(let localeCode) = rawLocale,
                        case .JSONArray(let content)     = rawContent else {
                            callback(.InvalidJSON(translation))
                            return
                    }
                    
                    self.locale = localeCode
                    
                    // parse and append content to this page
                    for c in content {
                        do {
                            let obj = try AMPContent.factory(c)
                            self.appendContent(obj)
                        } catch {
                            // Content could not be deserialized, do not add to page
                            if AMP.config.loggingEnabled {
                                print("AMP: Deserialization failed")
                            }
                        }
                    }
                }
            }
            
            // reset to using cache
            self.useCache = true
            
            // all finished, call block
            callback(nil)
        }
    }
    
    /// Recursively append all content
    /// 
    /// - parameter obj: the content object to append including it's children
    private func appendContent(obj:AMPContent) {
        self.content.append(obj)

        // append all toplevel content
        if case let container as AMPContainerContent = obj {
            if let children = container.children {
                for child in children {
                    // container's children are appended on base level to be able to find them quicker
                    self.content.append(child)
                }
            }
        }
    }
}


class ErrorHandlingAMPPage: AMPPage {
    private var errorHandler: (AMPError -> Void)
    
    init(page: AMPPage, errorHandler: (AMPError -> Void)) {
        self.errorHandler = errorHandler
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
    
    /// override default error callback to bubble error up to AMP object
    override internal func callErrorHandler(error: AMPError) {
        errorHandler(error)
    }
}

public class CancelableAMPPage: AMPPage {

    init(page: AMPPage) {
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

    public func cancel() {
        dispatch_barrier_async(self.workQueue) {
            self.hasFailed = true
            self.finish()
        }
    }
    
    public func finish() {
        dispatch_barrier_async(self.workQueue) {
            self.collection.pageCache.removeValueForKey(self.identifier + "-" + self.uuid)
        }
    }
}