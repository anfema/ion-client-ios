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
    public var hasFailed: Bool = false
    
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
    
    
    // MARK: Initializer
    
    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter layout: the page layout
    /// - Parameter useCache: set to false to force a page refresh
    /// - Parameter callback: the block to call when initialization finished
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
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the page
    public func onError(callback: (AMPError -> Void)) -> AMPPage {
        return ErrorHandlingAMPPage(page: self, errorHandler: callback)
    }
    
    /// override default error callback to bubble error up to collection
    internal func callErrorHandler(error: AMPError) {
        self.collection.callErrorHandler(error)
    }
    
    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - Parameter name: outlet name to fetch
    /// - Parameter callback: block to execute when outlet was found, will not be called if no such outlet
    ///                       exists or there was any kind of communication error while fetching the page
    /// - Returns: self to be able to chain another call
    public func outlet(name: String, callback: (AMPContent -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }

            // search content
            var cObj:AMPContent? = nil
            for content in self.content {
                if content.outlet == name {
                    cObj = content
                    break
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
    /// - Parameter name: outlet name to fetch
    /// - Returns: content object if page was loaded and outlet exists
    public func outlet(name: String) -> AMPContent? {
        if !self.isReady {
            // cannot return outlet synchronously from a async loading page
            return nil
        } else {
            // search content
            var cObj:AMPContent? = nil
            for content in self.content {
                if content.outlet == name {
                    cObj = content
                    break
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
    /// - Parameter name: outlet to check
    /// - Parameter callback: callback to call
    /// - Returns: self for chaining
    public func outletExists(name: String, callback: (Bool -> Void)) -> AMPPage {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
       
            // search content
            var found = false
            for content in self.content {
                if content.outlet == name {
                    found = true
                    break
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
    /// - Parameter name: outlet to check
    /// - Returns: true if outlet exists else false, nil if page not loaded
    public func outletExists(name: String) -> Bool? {
        if !self.isReady {
            // cannot return outlet synchronously from a async loading page
            return nil
        } else {
            // search content
            for content in self.content {
                if content.outlet == name {
                    return true
                }
            }
            return false
        }
    }
    
    // MARK: Private
    
    private init(forErrorHandlerWithCollection collection: AMPCollection, identifier: String, locale: String) {
        self.locale = locale
        self.useCache = true
        self.collection = collection
        self.identifier = identifier
        self.layout = ""
        self.workQueue = dispatch_queue_create("com.anfema.amp.page.\(identifier).withErrorHandler.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)
        
        // FIXME: How to remove this from the collection cache again?
        self.collection.pageCache[identifier + "-" + NSUUID().UUIDString] = self
    }

    /// Fetch page from cache or web
    ///
    /// - Parameter identifier: page identifier to get
    /// - Parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(AMPError? -> Void)) {
        AMPRequest.fetchJSON("pages/\(self.collection.identifier)/\(identifier)", queryParameters: [ "locale" : self.collection.locale ], cached:self.useCache) { result in
            if case .Failure = result {
                callback(.PageNotFound(identifier))
                return
            }

            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    callback(.JSONObjectExpected(result.value!))
                    return
            }
            
            // furthermore we need a page and a last_updated element
            guard dict["page"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["page"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    callback(.JSONObjectExpected(dict["page"]))
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {

                // make sure everything is there
                guard (dict["identifier"] != nil) && (dict["translations"] != nil),
                      case .JSONString(let id) = dict["identifier"]!,
                      let parent = dict["parent"],
                      case .JSONArray(let translations) = dict["translations"]! else {
                        callback(.InvalidJSON(result.value))
                        return
                }
                
                if case .JSONString(let parentID) = parent {
                    self.parent = parentID
                } else {
                    self.parent = nil
                }
                self.identifier = id

                // we only process the first translation as we used the `locale` filter in the request
                if translations.count > 0 {
                    let translation = translations[0]
                    
                    // guard against garbage data
                    guard case .JSONDictionary(let t) = translation else {
                        callback(.JSONObjectExpected(translation))
                        return
                    }
                    
                    // make sure the translation contains all needed fields
                    guard (t["locale"] != nil) && (t["content"] != nil),
                        case .JSONString(let localeCode) = t["locale"]!,
                        case .JSONArray(let content)     = t["content"]! else {
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
                            print("AMP: Deserialization failed")
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
    /// - Parameter obj: the content object to append including it's children
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
        super.init(forErrorHandlerWithCollection: page.collection, identifier: page.identifier, locale: page.locale)
        
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
            page.parentLock.unlock()
        }
    }
    
    /// override default error callback to bubble error up to AMP object
    override internal func callErrorHandler(error: AMPError) {
        errorHandler(error)
    }
}