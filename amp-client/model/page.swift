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

public class AMPPage : AMPChainable<String, AMPContent>, CustomStringConvertible {
    public var identifier:String
    public var collection:AMPCollection
    public var lastUpdate:NSDate!
    public var locale:String
    public var isProxy:Bool

    public var content = Array<AMPContent>()

    private var useCache = false

    public var description: String {
        return "AMPPage: \(identifier), \(content.count) content items"
    }

    // MARK: Initializer
    public convenience init(collection: AMPCollection, identifier: String) {
        self.init(collection: collection, identifier: identifier, useCache: true)
    }
    
    public convenience init(collection: AMPCollection, identifier: String, callback:(AMPPage -> Void)) {
        self.init(collection: collection, identifier:identifier, useCache: true, callback:callback)
    }
    
    public init(collection: AMPCollection, identifier: String, useCache: Bool) {
        // Lazy initializer, if this is used the page is not loaded but loading will start
        // in background, so we need to ask the collection's pageCache for the real instance
        // and act as a proxy to that instance
        self.identifier = identifier
        self.collection = collection
        self.useCache = useCache
        self.locale = self.collection.locale
        self.isProxy = true
    }

    public init(collection: AMPCollection, identifier: String, useCache: Bool, callback:(AMPPage -> Void)) {
        // Full async initializer, self will be populated async
        self.identifier = identifier
        self.collection = collection
        self.useCache = useCache
        self.locale = self.collection.locale
        self.isProxy = false
        super.init()
        
        self.fetch(identifier) {
            self.isReady = true
            for cObj in self.content {
                if let o = cObj.getBaseObject() {
                    self.callCallbacks(o.outlet, value: cObj, error: nil)
                    
                    // call all proxy object callbacks
                    if let proxy = self.collection.getCachedPage(self.identifier, proxy: true) {
                        proxy.callCallbacks(o.outlet, value: cObj, error: nil)
                    }
                }
            }
            callback(self)
        }
    }
    
    // MARK: Async API
    public func onError(callback: (ErrorType -> Void)) {
        // enqueue error callback for lazy resolving
        errorCallbacks.append(callback)
    }

    public func outlet(name: String, callback: (AMPContent -> Void)) {
        if self.isProxy {
            callbacks.append((name, callback))
        } else {
            // search content
            var cObj:AMPContent? = nil
            for content in self.content {
                if let c = content.getBaseObject() {
                    if c.outlet == name {
                        cObj = content
                        break
                    }
                }
            }
            if let c = cObj {
                callback(c)
            }
        }
        
    }
   
    public func outlet(name: String) -> AMPContent? {
        if self.isProxy {
            return nil
        } else {
            // search content
            var cObj:AMPContent? = nil
            for content in self.content {
                if let c = content.getBaseObject() {
                    if c.outlet == name {
                        cObj = content
                        break
                    }
                }
            }
            return cObj
        }
    }
    
    // MARK: Private
    
    private func fetch(identifier: String, callback:(Void -> Void)) {
        // TODO: this url is not unique, fix in backend
        AMPRequest.fetchJSON("pages/\(identifier)", queryParameters: [ "locale" : self.collection.locale ], cached:self.useCache) { result in
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    self.error = AMPError.Code.JSONObjectExpected(result.value!)
                    return
            }
            guard dict["page"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["page"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    self.error = AMPError.Code.JSONObjectExpected(dict["page"])
                    return
            }
            self.lastUpdate = NSDate(timeIntervalSince1970: timestamp)

            
            if case .JSONDictionary(let dict) = array[0] {
                guard (dict["identifier"] != nil) && (dict["translations"] != nil),
                      case .JSONString(let identifier) = dict["identifier"]!,
                      case .JSONArray(let translations) = dict["translations"]! else {
                        self.error = AMPError.Code.InvalidJSON(result.value)
                        return
                }
                
                self.identifier = identifier

                if translations.count > 0 {
                    let translation = translations[0]
                    guard case .JSONDictionary(let t) = translation else {
                        self.error = AMPError.Code.JSONObjectExpected(translation)
                        return
                    }
                    guard (t["locale"] != nil) && (t["content"] != nil),
                        case .JSONString(let localeCode) = t["locale"]!,
                        case .JSONArray(let content)     = t["content"]! else {
                            self.error = AMPError.Code.InvalidJSON(translation)
                            return
                    }
                    
                    self.locale = localeCode
                    
                    for c in content {
                        do {
                            let obj = try AMPContent(json: c)
                            self.appendContent(obj)
                        } catch {
                            // Content could not be deserialized, do not add to page
                        }
                    }
                }
            }
            self.useCache = true
            callback()
        }
    }
    
    private func appendContent(obj:AMPContent) {
        // recursively append all content
        switch obj {
        case .Container(let container):
            if let children = container.children {
                for child in children {
                    self.appendContent(child)
                }
            }
        default: break
        }
        self.content.append(obj)
    }
}

