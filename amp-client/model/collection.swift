//
//  collection.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

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
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["last_changed"] != nil) && (dict["parent"] != nil) &&
              (dict["identifier"] != nil) && (dict["layout"] != nil),
              case .JSONString(let lastChanged) = dict["last_changed"]!,
              case .JSONString(let layout) = dict["layout"]!,
              case .JSONString(let identifier)  = dict["identifier"]! else {
                throw AMPError.Code.InvalidJSON(json)
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
            throw AMPError.Code.InvalidJSON(json)
        }
    }
    
    public var imageURL:NSURL? {
        if let thumbnail = self.thumbnail {
            return NSURL(string: thumbnail)!
        }
        return nil
    }
}

/// compare two collections
public func ==(lhs: AMPCollection, rhs: AMPCollection) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

/// Collection class, contains pages, has functionality to async fetch data
public class AMPCollection : AMPChainable<AMPPage>, CustomStringConvertible, Equatable, Hashable {
    
    /// identifier
    public var identifier:String!
    
    /// locale code
    public var locale:String!

    /// default locale for this collection
    public var defaultLocale:String?
    
    /// last update date
    public var lastUpdate:NSDate?

    /// set to false to avoid using the cache (refreshes, etc.)
    private var useCache = true
    
    /// page metadata
    internal var pageMeta = [AMPPageMeta]()

    /// CustomStringConvertible requirement
    public var description: String {
        return "AMPCollection: \(identifier!), \(pageMeta.count) pages"
    }
    
    /// Hashable requirement
    public var hashValue: Int {
        return identifier.hashValue
    }

    // MARK: - Initializer
    
    /// Initialize collection async
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// - Parameter identifier: the collection identifier
    /// - Parameter locale: locale code to fetch
    /// - Parameter useCache: set to false to force a refresh
    /// - Parameter callback: block to call when collection is fully loaded
    init(identifier: String, locale: String, useCache: Bool, callback:(AMPCollection -> Void)) {
        super.init()
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        
        // here we can call the callback directly
        self.fetch(identifier) {
            self.isReady = true
            callback(self)
        }
    }

    /// Initialize collection
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// This one queues all actions until it has been fully loaded.
    ///
    /// - Parameter identifier: the collection identifier
    /// - Parameter locale: locale code to fetch
    /// - Parameter useCache: set to false to force a refresh
    init(identifier: String, locale: String, useCache: Bool) {
        super.init()
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        
        // there is no callback so there may be queued tasks
        self.fetch(identifier) {
            self.isReady = true
            self.executeTasks()
        }
    }

    /// Initialize collection using cache
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// - Parameter identifier: the collection identifier
    /// - Parameter locale: locale code to fetch
    /// - Parameter callback: block to call when collection is fully loaded
    convenience init(identifier: String, locale: String, callback:(AMPCollection -> Void)) {
        self.init(identifier: identifier, locale: locale, useCache: true, callback: callback)
    }

    /// Initialize collection using cache
    ///
    /// use `collection` method of `AMP` class instead!
    ///
    /// This one queues all actions until it has been fully loaded.
    ///
    /// - Parameter identifier: the collection identifier
    /// - Parameter locale: locale code to fetch
    convenience init(identifier: String, locale: String) {
        self.init(identifier: identifier, locale: locale, useCache: true)
    }

    // MARK: - API
    
    /// Fetch a page from this collection
    ///
    /// - Parameter identifier: page identifier
    /// - Parameter callback: the callback to call when the page becomes available
    /// - Returns: self, to be able to chain more actions to the collection
    public func page(identifier: String, callback:(AMPPage -> Void)) -> AMPCollection {
        // register callback with async queue
        self.appendCallback(identifier, callback: callback)
        
        // this block fetches the page from the cache or web and calls the associated callbacks
        let block:(String -> Void) = { identifier in
            if let page = AMP.getCachedPage(self, identifier: identifier) {
                var needsUpdate:Bool = false
                // ready, check if we need to update
                if page.isReady {
                    if let lastUpdate = self.getMetaUpdate(page) {
                        if page.lastUpdate.compare(lastUpdate) == NSComparisonResult.OrderedAscending {
                            // page out of date, force update
                            needsUpdate = true
                        }
                    }
                    if !needsUpdate {
                        // no update return instantly
                        self.callCallbacks(identifier, value: page, error: nil)
                    }
                }
                if page.hasFailed {
                    needsUpdate = true
                }
                if needsUpdate {
                    // fetch page update
                    let parent = self.getParentForPage(identifier)
                    let layout = self.getLayoutForPage(identifier)

                    AMP.cachePage(AMPPage(collection: self, identifier: identifier, layout: layout, parent:parent) { page in
                        self.callCallbacks(identifier, value: page, error: nil)
                    })
                }
            } else {
                let parent = self.getParentForPage(identifier)
                let layout = self.getLayoutForPage(identifier)
                AMP.cachePage(AMPPage(collection: self, identifier: identifier, layout: layout, parent:parent) { page in
                    self.callCallbacks(identifier, value: page, error: nil)
                })
            }
        }
        
        // append the task to fetch the page, if a similar block is already in the task queue it will be discarded
        self.appendTask(identifier, block: block)
        
        // allow further chaining
        return self
    }

    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves async once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - Parameter identifier: page identifier
    /// - Returns: a page that resolves automatically if the underlying page becomes available
    public func page(identifier: String) -> AMPPage {
        // fetch page and resume processing when ready
        self.appendCallback(identifier, callback: { page in }) // have at least one callback, even if it does nothing
        var fetch = true
        
        if let page = AMP.getCachedPage(self, identifier: identifier) {
            // well page is cached, just return cached version
            if page.isReady {
                fetch = false
                return page
            }
        }
        
        if fetch {
            // search metadata
            // FIXME: 2 runs for searching metadata
            let parent = self.getParentForPage(identifier)
            let layout = self.getLayoutForPage(identifier)
            
            // not cached, fetch from web and add it to the cache
            let page = AMPPage(collection: self, identifier: identifier, layout:layout, parent: parent) { page in
                self.callCallbacks(identifier, value: page, error: nil)
            }
            AMP.cachePage(page)
            return page
        }
    }
    
    // TODO: public func page(index: Int) -> AMPPage
  
    /// Enumerate pages
    ///
    /// - Parameter callback: block to call for each page
    public func pages(callback: (AMPPage -> Void)) -> AMPCollection {
        // this block fetches the page list after the collection is ready
        let block:(String -> Void) = { identifier in
            for meta in self.pageMeta {
                if meta.parent == nil {
                    self.page(meta.identifier, callback:callback)
                }
            }
        }
        
        // append the task to fetch the pages
        self.appendTask("pageList", deduplicate:false, block: block)
        
        return self
    }
    
    /// Fetch page count
    ///
    /// - Parameter parent: parent to get page count for, nil == top level
    /// - Parameter callback: block to call for page count return value
    public func pageCount(parent: String?, callback: (Int -> Void)) -> AMPCollection {
        // this block fetches the page count after the collection is ready
        let block:(String -> Void) = { identifier in
            var count = 0
            for meta in self.pageMeta {
                if meta.parent == parent {
                    count++
                }
            }
            callback(count)
        }
        
        // append the task to fetch the pages
        self.appendTask("pageCount", deduplicate:false, block: block)

        return self
    }
    
    /// Fetch metadata
    ///
    /// - Parameter identifier: page identifier to get metadata for
    /// - Parameter callback: callback to call with metadata
    public func metadata(identifier: String, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        // this block fetches the page count after the collection is ready
        let block:(String -> Void) = { _ in
            var found = false
            for meta in self.pageMeta {
                if meta.identifier == identifier {
                    callback(meta)
                    found = true
                    break
                }
            }
            if !found {
                AMP.callError(self.identifier, error: AMPError.Code.PageNotFound(identifier))
            }
        }
        
        // append the task to fetch the pages
        self.appendTask("pageMetadata", deduplicate:false, block: block)
        
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
        // this block fetches the page metadata after the collection is ready
        let block:(String -> Void) = { identifier in
            var result = [AMPPageMeta]()
            for meta in self.pageMeta {
                if meta.parent == parent {
                    result.append(meta)
                }
            }
            if result.count == 0 {
                if let parent = parent {
                    AMP.callError(self.identifier, error: AMPError.Code.PageNotFound(parent))
                } else {
                    AMP.callError(self.identifier, error: AMPError.Code.CollectionNotFound(self.identifier))
                }
            } else {
                callback(result)
            }
        }
        
        // append the task to fetch the pages
        self.appendTask("pageMetadataList", deduplicate:false, block: block)
        
        return self
    }
    
    /// Error handler to chain to the collection
    ///
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the collection
    public func onError(callback: (AMPError.Code -> Void)?) -> AMPCollection {
        // enqueue error callback for lazy resolving
        self.appendErrorCallback(callback)
        return self
    }
    
    /// override default error callback to bubble error up to AMP object
    override func defaultErrorCallback(error: AMPError.Code) {
        AMP.callError(self.identifier, error: error)
    }
    
    // MARK: - Internal
    
    internal func getChildIdentifiersForPage(parent: String) -> [String] {
        var result:[String] = []
        for meta in self.pageMeta {
            if meta.parent == parent {
                result.append(meta.identifier)
            }
        }
        return result
    }
   
    // MARK: - Private
    
    private func getParentForPage(identifier: String) -> String? {
        var parent: String? = nil
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                parent = meta.parent
                break
            }
        }
        return parent
    }

    private func getLayoutForPage(identifier: String) -> String {
        var layout: String = ""
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                layout = meta.layout
                break
            }
        }
        return layout
    }

    private func getMetaUpdate(page: AMPPage) -> NSDate? {
        var update: NSDate? = nil
        for meta in self.pageMeta {
            if meta.identifier == page.identifier {
                update = meta.lastChanged
                break
            }
        }
        return update
    }
    
    /// Fetch collection from cache or web
    ///
    /// - Parameter identifier: collection identifier to get
    /// - Parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(Void -> Void)) {
        AMPRequest.fetchJSON("collections/\(identifier)", queryParameters: [ "locale" : self.locale ], cached:self.useCache) { result in
            if case .Failure = result {
                AMP.callError(identifier, error: AMPError.Code.CollectionNotFound(identifier))
                self.hasFailed = true
                return
            }
            
            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    AMP.callError(identifier, error: AMPError.Code.JSONObjectExpected(result.value!))
                    self.hasFailed = true
                    return
            }
            
            // furthermore we need a collection and a last_updated element
            guard dict["collection"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["collection"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    AMP.callError(identifier, error: AMPError.Code.JSONObjectExpected(result.value!))
                    self.hasFailed = true
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
                        AMP.callError(identifier, error: AMPError.Code.InvalidJSON(result.value!))
                        self.hasFailed = true
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
            callback()
        }
    }
 }