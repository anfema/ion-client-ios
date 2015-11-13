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

/// Page metadata, used if only small samples of a page have to be used instead of downloading the whole thing
public class AMPPageMeta: CanLoadImage {
    /// static date formatter to save allocation times
    static let formatter:NSDateFormatter = NSDateFormatter()
    static let formatter2:NSDateFormatter = NSDateFormatter()

    /// flag if the date formatter has already been instanciated
    static var formatterInstanciated = false
    
    /// page identifier
    public var identifier:String!
    
    /// parent identifier, nil == top level
    public var parent:String?
    
    /// last change date
    public var lastChanged:NSDate!
    
    /// page title if available
    public var title:String?
    
    /// page layout
    public var layout:String!
    
    /// thumbnail URL if available, if you want the UIImage use convenience functions below
    public var thumbnail:String?
    
    /// Init metadata from JSON object
    ///
    /// - Parameter json: serialized JSON object of page metadata
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON
    internal init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["last_changed"] != nil) && (dict["parent"] != nil) &&
              (dict["identifier"] != nil) && (dict["layout"] != nil),
              case .JSONString(let lastChanged) = dict["last_changed"]!,
              case .JSONString(let layout) = dict["layout"]!,
              case .JSONString(let identifier)  = dict["identifier"]! else {
                throw AMPError.InvalidJSON(json)
        }
        

        if !AMPPageMeta.formatterInstanciated {
            AMPPageMeta.formatter.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"
            AMPPageMeta.formatter.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
            AMPPageMeta.formatter.locale      = NSLocale(localeIdentifier: "en_US_POSIX")

            AMPPageMeta.formatter2.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
            AMPPageMeta.formatter2.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
            AMPPageMeta.formatter2.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
            AMPPageMeta.formatterInstanciated = true
        }
        
        // avoid crashing if microseconds are not there
        var lc = AMPPageMeta.formatter.dateFromString(lastChanged)
        if lc == nil {
           lc = AMPPageMeta.formatter2.dateFromString(lastChanged)
        }
        self.lastChanged = lc
        self.identifier  = identifier
        self.layout = layout
        
        if (dict["title"]  != nil) {
            if case .JSONString(let title) = dict["title"]! {
                self.title = title
            }
        }

        if (dict["thumbnail"]  != nil) {
            if case .JSONString(let thumbnail) = dict["thumbnail"]! {
                self.thumbnail = thumbnail
            }
        }

        switch(dict["parent"]!) {
        case .JSONNull:
            self.parent = nil
        case .JSONString(let parent):
            self.parent = parent
        default:
            throw AMPError.InvalidJSON(json)
        }
    }
    
    public var imageURL:NSURL? {
        if let thumbnail = self.thumbnail {
            return NSURL(string: thumbnail)!
        }
        return nil
    }
}

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
    /// - Parameter identifier: the collection identifier
    /// - Parameter locale: locale code to fetch
    /// - Parameter useCache: set to false to force a refresh
    /// - Parameter callback: block to call when collection is fully loaded
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
    
    private init(forErrorHandlerWithIdentifier identifier: String, locale: String) {
        self.locale = locale
        self.useCache = true
        self.identifier = identifier
        self.workQueue = dispatch_queue_create("com.anfema.amp.collection.\(identifier).withErrorHandler.\(NSDate().timeIntervalSince1970)", DISPATCH_QUEUE_SERIAL)

        // FIXME: How to remove this from the collection cache again?
        AMP.collectionCache[identifier + "-" + NSUUID().UUIDString] = self
    }

     // MARK: - API
    
    /// Fetch a page from this collection
    ///
    /// - Parameter identifier: page identifier
    /// - Parameter callback: the callback to call when the page becomes available
    /// - Returns: self, to be able to chain more actions to the collection
    public func page(identifier: String, callback:(AMPPage -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            if let page = self.getCachedPage(self, identifier: identifier) {
                let updateBlock:(Void -> Void) = {
                    // fetch page update
                    guard let meta = self.getPageMetaForPage(identifier) else {
                        return
                    }
                    self.cachePage(AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: true, parent:meta.parent) { page in
                        callback(page)
                        })
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
                self.cachePage(AMPPage(collection: self, identifier: identifier, layout: meta.layout, useCache: true, parent:meta.parent) { page in
                    callback(page)
                })
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
    /// - Parameter identifier: page identifier
    /// - Returns: a page that resolves automatically if the underlying page becomes available, nil if page unknown
    public func page(identifier: String) -> AMPPage {
        // fetch page and resume processing when ready
        var fetch = true
        
        if let page = self.getCachedPage(self, identifier: identifier) {
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
            if let meta = self.getPageMetaForPage(identifier) {
                layout = meta.layout
                parent = meta.parent
            }
            
            // not cached, fetch from web and add it to the cache
            let page = AMPPage(collection: self, identifier: identifier, layout: layout, useCache: true, parent: parent) { page in
            }
            self.cachePage(page)
            return page
        }
    }
    
    // TODO: public func page(index: Int) -> AMPPage
  
    /// Enumerate pages
    ///
    /// - Parameter callback: block to call for each page
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
    
    /// Fetch page count
    ///
    /// - Parameter parent: parent to get page count for, nil == top level
    /// - Parameter callback: block to call for page count return value
    public func pageCount(parent: String?, callback: (Int -> Void)) -> AMPCollection {
        // append page count to work queue
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var count = 0
            for meta in self.pageMeta {
                if meta.parent == parent {
                    count++
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(count)
            }
        }
        
        return self
    }
    
    /// Fetch metadata
    ///
    /// - Parameter identifier: page identifier to get metadata for
    /// - Parameter callback: callback to call with metadata
    public func metadata(identifier: String, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        // this block fetches the page count after the collection is ready
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var found = false
            for meta in self.pageMeta {
                if meta.identifier == identifier {
                    dispatch_async(AMP.config.responseQueue) {
                        callback(meta)
                    }
                    found = true
                    break
                }
            }
            if !found {
                self.callErrorHandler(.PageNotFound(identifier))
            }
        }

        return self
    }

    /// Enumerate metadata
    ///
    /// - Parameter parent: parent to enumerate metadata for, nil == top level
    /// - Parameter callback: callback to call with metadata
    public func enumerateMetadata(parent: String?, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        self.metadataList(parent) { list in
            for listItem in list {
                callback(listItem)
            }
        }
        
        return self
    }
    
    /// Fetch metadata as list
    ///
    /// - Parameter parent: parent to enumerate metadata for, nil == top level
    /// - Parameter callback: callback to call with metadata
    public func metadataList(parent: String?, callback: ([AMPPageMeta] -> Void)) -> AMPCollection {
        // fetch the page metadata after the collection is ready
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var result = [AMPPageMeta]()
            for meta in self.pageMeta {
                if meta.parent == parent {
                    result.append(meta)
                }
            }
            if result.count == 0 {
                if let parent = parent {
                    self.callErrorHandler(.PageNotFound(parent))
                } else {
                    self.callErrorHandler(.CollectionNotFound(self.identifier))
                }
            } else {
                dispatch_async(AMP.config.responseQueue) {
                    callback(result)
                }
            }
        }
        
        return self
    }
    
    /// Error handler to chain to the collection
    ///
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the collection
    public func onError(callback: (AMPError -> Void)) -> AMPCollection {
        return ErrorHandlingAMPCollection(collection: self, errorHandler: callback)
    }
    
    /// override default error callback to bubble error up to AMP object
    internal func callErrorHandler(error: AMPError) {
        AMP.callError(self.identifier, error: error)
    }
    
    // MARK: - Internal
    
    internal func getChildIdentifiersForPage(parent: String, callback:([String] -> Void)) {
        dispatch_async(self.workQueue) {
            var result:[String] = []
            for meta in self.pageMeta {
                if meta.parent == parent {
                    result.append(meta.identifier)
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(result)
            }
        }
    }
   
    // MARK: - Private
    private func getPageMetaForPage(identifier: String) -> AMPPageMeta? {
        var result: AMPPageMeta? = nil
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                result = meta
                break
            }
        }
        return result
    }
    
    /// Fetch page from cached page list
    ///
    /// - Parameter collection: a collection object
    /// - Parameter identifier: the identifier of the page to fetch
    /// - Returns: page object or nil if not found
    internal func getCachedPage(collection: AMPCollection, identifier: String) -> AMPPage? {
        return self.pageCache[identifier]
    }
    
    /// Save page to the page cache overwriting older versions
    ///
    /// - Parameter page: the page to add to the cache
    private func cachePage(page: AMPPage) {
        self.pageCache[page.identifier] = page
    }

    /// Fetch collection from cache or web
    ///
    /// - Parameter identifier: collection identifier to get
    /// - Parameter callback: block to call when the fetch finished
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
                        let obj = try AMPPageMeta(json: page)
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

extension AMPCollection: CustomStringConvertible {
    public var description: String {
        return "AMPCollection: \(identifier!), \(pageMeta.count) pages"
    }
}

public func ==(lhs: AMPCollection, rhs: AMPCollection) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

extension AMPCollection: Hashable {
    public var hashValue: Int {
        return identifier.hashValue
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
