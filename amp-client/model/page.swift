//
//  page.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import Alamofire
import DEjson

// FIXME: do we have a dependency circle with `collection` attribute and pagecache in the collection?

public func ==(lhs: AMPPage, rhs: AMPPage) -> Bool {
    return (lhs.collection.identifier == rhs.collection.identifier) && (lhs.identifier == rhs.identifier) && (lhs.isProxy == rhs.isProxy)
}

public class AMPPage : AMPChainable<AMPContent>, CustomStringConvertible, Equatable, Hashable {
    public var identifier:String            /// page identifier
    public var collection:AMPCollection     /// collection of this page
    public var lastUpdate:NSDate!           /// last update date of this page
    public var locale:String                /// locale code for the page
    public var isProxy:Bool                 /// full instance or proxy?

    public var content = [AMPContent]()     /// content list

    private var useCache = false            /// set to true to avoid fetching from cache

    /// CustomStringConvertible
    public var description: String {
        return "AMPPage: \(identifier), \(content.count) content items"
    }
    
    /// Hashable requirement
    public var hashValue: Int {
        return self.collection.hashValue + self.identifier.hashValue + self.isProxy.hashValue
    }
    
    // MARK: Initializer
    
    /// Initialize page for collection (uses cache, initializes proxy)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    convenience init(collection: AMPCollection, identifier: String) {
        self.init(collection: collection, identifier: identifier, useCache: true)
    }

    /// Initialize page for collection (uses cache, initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter callback: the block to call when initialization finished
    convenience init(collection: AMPCollection, identifier: String, callback:(AMPPage -> Void)) {
        self.init(collection: collection, identifier:identifier, useCache: true, callback:callback)
    }
    
    /// Initialize page for collection (initializes proxy)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter useCache: set to false to force a page refresh
    init(collection: AMPCollection, identifier: String, useCache: Bool) {
        // Lazy initializer, if this is used the page is not loaded but loading will start
        // in background, so we need to ask the collection's pageCache for the real instance
        // and act as a proxy to that instance
        self.identifier = identifier
        self.collection = collection
        self.useCache = useCache
        self.locale = self.collection.locale
        self.isProxy = true
    }

    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter useCache: set to false to force a page refresh
    /// - Parameter callback: the block to call when initialization finished
    init(collection: AMPCollection, identifier: String, useCache: Bool, callback:(AMPPage -> Void)) {
        // Full async initializer, self will be populated async
        self.identifier = identifier
        self.collection = collection
        self.useCache = useCache
        self.locale = self.collection.locale
        self.isProxy = false
        super.init()
        
        // fetch page async
        self.fetch(identifier) {
            self.isReady = true
            for o in self.content {
                self.callCallbacks(o.outlet, value: o, error: nil)
                
                // call all proxy object chained callbacks
                if let proxy = AMP.getCachedPage(self.collection, identifier: self.identifier, proxy: true) {
                    proxy.callCallbacks(o.outlet, value: o, error: nil)
                }
            }
            
            
            // all callbacks that are queued in the proxy now would have failed on a real object
            // so we call an error callback for each entry
            if let proxy = AMP.getCachedPage(self.collection, identifier: self.identifier, proxy: true) {
                let failedIdentifiers = proxy.getQueuedIdentifiers()
                for identifier in failedIdentifiers {
                    proxy.callError(identifier, error: AMPError.Code.OutletNotFound(identifier))
                }
            }
            callback(self)
        }
    }
    
    // MARK: Async API
    
    // TODO: children as child("test")
    
    /// Error handler to chain to the page
    ///
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the page
    public func onError(callback: (AMPError.Code -> Void)) -> AMPPage {
        // enqueue error callback for lazy resolving
        self.appendErrorCallback(callback)
        return self
    }

    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - Parameter name: outlet name to fetch
    /// - Parameter callback: block to execute when outlet was found, will not be called if no such outlet
    ///                       exists or there was any kind of communication error while fetching the page
    /// - Returns: self to be able to chain another call
    public func outlet(name: String, callback: (AMPContent -> Void)) -> AMPPage {
        self.appendCallback(name, callback: callback)

        // resolve instantly if possible
        if !self.isProxy {
            // search content
            var cObj:AMPContent? = nil
            for content in self.content {
                if content.outlet == name {
                    cObj = content
                    break
                }
            }
            if let c = cObj {
                callback(c)
            } else {
                self.callError(name, error: AMPError.Code.OutletNotFound(name))
            }
        }
        return self
    }
   
    /// Fetch an outlet by name (from loaded page)
    ///
    /// - Parameter name: outlet name to fetch
    /// - Returns: content object if page was no proxy and outlet exists
    public func outlet(name: String) -> AMPContent? {
        if self.isProxy {
            // cannot return outlet synchronously from a proxy
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
            return cObj
        }
    }
    
    // MARK: Private
    
    /// Fetch page from cache or web
    ///
    /// - Parameter identifier: page identifier to get
    /// - Parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(Void -> Void)) {
        // FIXME: this url is not unique, fix in backend
        AMPRequest.fetchJSON("pages/\(identifier)", queryParameters: [ "locale" : self.collection.locale ], cached:self.useCache) { result in
            if case .Failure = result {
                self.collection.callError(identifier, error: AMPError.Code.PageNotFound(identifier))
                return
            }

            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    self.collection.callError(identifier, error: AMPError.Code.JSONObjectExpected(result.value!))
                    return
            }
            
            // furthermore we need a page and a last_updated element
            guard dict["page"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["page"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    self.collection.callError(identifier, error: AMPError.Code.JSONObjectExpected(dict["page"]))
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {

                // make sure everything is there
                guard (dict["identifier"] != nil) && (dict["translations"] != nil),
                      case .JSONString(let id) = dict["identifier"]!,
                      case .JSONArray(let translations) = dict["translations"]! else {
                        self.collection.callError(identifier, error: AMPError.Code.InvalidJSON(result.value))
                        return
                }
                
                self.identifier = id

                // we only process the first translation as we used the `locale` filter in the request
                if translations.count > 0 {
                    let translation = translations[0]
                    
                    // guard against garbage data
                    guard case .JSONDictionary(let t) = translation else {
                        self.collection.callError(identifier, error:AMPError.Code.JSONObjectExpected(translation))
                        return
                    }
                    
                    // make sure the translation contains all needed fields
                    guard (t["locale"] != nil) && (t["content"] != nil),
                        case .JSONString(let localeCode) = t["locale"]!,
                        case .JSONArray(let content)     = t["content"]! else {
                            self.collection.callError(identifier, error: AMPError.Code.InvalidJSON(translation))
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
            callback()
        }
    }
    
    /// Recursively append all content
    /// 
    /// - Parameter obj: the content object to append including it's children
    private func appendContent(obj:AMPContent) {
        // recursively append all content
        if case let container as AMPContainerContent = obj {
            if let children = container.children {
                for child in children {
                    // container's children are appended on base level to be able to find them quicker
                    // FIXME: Is this always a good idea or just for the default "layout" container
                    self.appendContent(child)
                }
            }
        }
        self.content.append(obj)
    }
}

