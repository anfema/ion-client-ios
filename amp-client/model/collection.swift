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
    var identifier:String!
    var parent:String?
    var lastChanged:NSDate!
    
    init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["last_changed"] != nil) && (dict["parent"] != nil) && (dict["identifier"] != nil),
              case .JSONString(let lastChanged) = dict["last_changed"]!,
              case .JSONString(let identifier)  = dict["identifier"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
        fmt.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
        fmt.locale     = NSLocale(localeIdentifier: "en_US_POSIX")
        
        self.lastChanged = fmt.dateFromString(lastChanged)
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
    public var identifier:String!
    public var locale:String!

    public var defaultLocale:String?
    public var lastUpdate:NSDate!

    private var useCache = false

    var pageCache = Array<AMPPage>()
    var pages = Array<AMPPageMeta>()

    public var description: String {
        return "AMPCollection: \(identifier!), \(pages.count) pages"
    }

    // MARK: Initializer
    public init(identifier: String, locale: String, useCache: Bool, callback:(AMPCollection -> Void)) {
        super.init()
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        self.fetch(identifier) {
            self.isReady = true
            callback(self)
        }
    }
    
    public init(identifier: String, locale: String, useCache: Bool) {
        super.init()
        self.locale = locale
        self.useCache = useCache
        self.identifier = identifier
        self.fetch(identifier) {
            self.isReady = true
            self.executeTasks()
        }
    }

    public convenience init(identifier: String, locale: String, callback:(AMPCollection -> Void)) {
        self.init(identifier: identifier, locale: locale, useCache: true, callback: callback)
    }
    
    public convenience init(identifier: String, locale: String) {
        self.init(identifier: identifier, locale: locale, useCache: true)
    }

    // MARK: API
    public func page(identifier: String, callback:(AMPPage -> Void)) -> AMPCollection {
        callbacks.append((identifier, callback))
        
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
        self.appendTask(identifier, block: block)
        return self
    }
    
    public func page(identifier: String) -> AMPPage {
        // fetch page and resume processing when ready

        if let page = self.getCachedPage(identifier, proxy: false) {
            return page
        } else {
            AMPPage(collection: self, identifier: identifier, callback: { page in
                self.pageCache.append(page)
                self.callCallbacks(identifier, value: page, error: nil)
            }).onError({ error in
                self.callCallbacks(identifier, value: nil, error: error)
            })
        }

        if let proxy = self.getCachedPage(identifier, proxy: true) {
            return proxy
        } else {
            let proxy = AMPPage(collection: self, identifier: identifier)
            self.pageCache.append(proxy)
            return proxy
        }
    }
  
    public func onError(callback: (ErrorType -> Void)) {
        // enqueue error callback for lazy resolving
        errorCallbacks.append(callback)
    }

    // MARK: Private
    public func getCachedPage(identifier: String, proxy: Bool) -> AMPPage? {
        for p in self.pageCache {
            if (p.identifier == identifier) && (p.isProxy == proxy) {
                return p
            }
        }
        return nil
    }
    
    private func fetch(identifier: String, callback:(Void -> Void)) {
        AMPRequest.fetchJSON("collections/\(identifier)", queryParameters: [ "locale" : self.locale ], cached:self.useCache) { result in
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    self.error = AMPError.Code.JSONObjectExpected(result.value!)
                    return
            }
            guard dict["collection"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["collection"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    self.error = AMPError.Code.JSONObjectExpected(result.value!)
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)
            
            if case .JSONDictionary(let dict) = array[0] {
                guard (dict["identifier"] != nil) && (dict["pages"] != nil) && (dict["default_locale"] != nil),
                      case .JSONString(let identifier)    = dict["identifier"]!,
                      case .JSONString(let defaultLocale) = dict["default_locale"]!,
                      case .JSONArray(let pages)          = dict["pages"]! else {
                        self.error = AMPError.Code.InvalidJSON(result.value!)
                        return
                }
            
                self.identifier = identifier
                self.defaultLocale = defaultLocale
            
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
            
            // revert to cache
            self.useCache = true
            callback()
        }
    }
 }