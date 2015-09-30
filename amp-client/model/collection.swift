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

class AMPPageMeta {
    static let formatter:NSDateFormatter = NSDateFormatter()
    static var formatterInstanciated = false
    
    var identifier:String!  /// page identifier
    var parent:String?      /// parent identifier
    var lastChanged:NSDate! /// last change date
    
    /// Init metadata from JSON object
    ///
    /// - Parameter json: serialized JSON object of page metadata
    /// - Throws: AMPError.Code.JSONObjectExpected, AMPError.Code.InvalidJSON
    init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["last_changed"] != nil) && (dict["parent"] != nil) && (dict["identifier"] != nil),
              case .JSONString(let lastChanged) = dict["last_changed"]!,
              case .JSONString(let identifier)  = dict["identifier"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        

        if !AMPPageMeta.formatterInstanciated {
            AMPPageMeta.formatter.dateFormat  = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'.'SSSSSS'Z'"
            AMPPageMeta.formatter.timeZone    = NSTimeZone(forSecondsFromGMT: 0)
            AMPPageMeta.formatter.locale      = NSLocale(localeIdentifier: "en_US_POSIX")
            AMPPageMeta.formatterInstanciated = true
        }
        
        self.lastChanged = AMPPageMeta.formatter.dateFromString(lastChanged)
        self.identifier  = identifier
        
        switch(dict["parent"]!) {
        case .JSONNull:
            self.parent = nil
        case .JSONString(let parent):
            self.parent = parent
        default:
            throw AMPError.Code.InvalidJSON(json)
        }
    }
}

public class AMPCollection : AMPChainable<String, AMPPage>, CustomStringConvertible {
    public var identifier:String!       /// identifier
    public var locale:String!           /// locale code

    public var defaultLocale:String?    /// default locale for this collection
    public var lastUpdate:NSDate!       /// last update date

    private var useCache = false        /// set to true to avoid using the cache (refreshes, etc.)

    var pageCache = [AMPPage]()         /// memory cache for pages
    var pages = [AMPPageMeta]()         /// page metadata

    /// CustomStringConvertible requirement
    public var description: String {
        return "AMPCollection: \(identifier!), \(pages.count) pages"
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
        callbacks.append((identifier, callback))
        
        // this block fetches the page from the cache or web and calls the associated callbacks
        let block:(String -> Void) = { identifier in
            if let page = self.getCachedPage(identifier, proxy: false) {
                self.callCallbacks(identifier, value: page, error: nil)
            } else {
                AMPPage(collection: self, identifier: identifier, callback: { page in
                    self.pageCache.append(page)
                    self.callCallbacks(identifier, value: page, error: nil)
                }).onError({ error in
                    self.callCallbacks(identifier, value: nil, error: error)
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
    /// As there is no callback, this returns a page proxy that resolves async once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - Parameter identifier: page identifier
    /// - Returns: a page or a proxy that resolves automatically if the underlying page becomes available
    public func page(identifier: String) -> AMPPage {
        // fetch page and resume processing when ready

        if let page = self.getCachedPage(identifier, proxy: false) {
            // well page is cached, just return cached version
            return page
        } else {
            // not cached, fetch from web and add it to the cache
            AMPPage(collection: self, identifier: identifier, callback: { page in
                self.pageCache.append(page)
                self.callCallbacks(identifier, value: page, error: nil)
            }).onError({ error in
                self.callCallbacks(identifier, value: nil, error: error)
            })
        }

        // if we get here the async page fetch has been initialized, so return a proxy
        if let proxy = self.getCachedPage(identifier, proxy: true) {
            // we had a cached proxy
            return proxy
        } else {
            // create a new proxy and add it to the cache
            let proxy = AMPPage(collection: self, identifier: identifier)
            self.pageCache.append(proxy)
            return proxy
        }
    }
  
    /// Error handler to chain to the collection
    ///
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the collection
    public func onError(callback: (ErrorType -> Void)) -> AMPCollection {
        // enqueue error callback for lazy resolving
        errorCallbacks.append(callback)
        return self
    }

    // MARK: - Internal
    
    /// Fetch page from cached page list
    ///
    /// - Parameter identifier: the identifier of the page to fetch
    /// - Parameter proxy: whether to fetch a proxy or a real page
    /// - Returns: page object or nil if not found
    func getCachedPage(identifier: String, proxy: Bool) -> AMPPage? {
        for p in self.pageCache {
            if (p.identifier == identifier) && (p.isProxy == proxy) {
                return p
            }
        }
        return nil
    }
    
    // MARK: - Private
    
    /// Fetch collection from cache or web
    ///
    /// - Parameter identifier: collection identifier to get
    /// - Parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(Void -> Void)) {
        AMPRequest.fetchJSON("collections/\(identifier)", queryParameters: [ "locale" : self.locale ], cached:self.useCache) { result in

            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    self.error = AMPError.Code.JSONObjectExpected(result.value!)
                    return
            }
            
            // furthermore we need a collection and a last_updated element
            guard dict["collection"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["collection"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    self.error = AMPError.Code.JSONObjectExpected(result.value!)
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if case .JSONDictionary(let dict) = array[0] {
                
                // make sure everything is there
                guard (dict["identifier"] != nil) && (dict["pages"] != nil) && (dict["default_locale"] != nil),
                      case .JSONString(let identifier)    = dict["identifier"]!,
                      case .JSONString(let defaultLocale) = dict["default_locale"]!,
                      case .JSONArray(let pages)          = dict["pages"]! else {
                        self.error = AMPError.Code.InvalidJSON(result.value!)
                        return
                }
            
                // initialize self
                self.identifier = identifier
                self.defaultLocale = defaultLocale
            
                // initialize page metadata objects from the collection's page array
                for page in pages {
                    do {
                        let obj = try AMPPageMeta(json: page)
                        self.pages.append(obj)
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