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

/// compare two pages for equality
public func ==(lhs: AMPPage, rhs: AMPPage) -> Bool {
    return (lhs.collection.identifier == rhs.collection.identifier) && (lhs.identifier == rhs.identifier)
}

/// Page class, contains functionality to fetch outlet content
public class AMPPage : AMPChainable<AMPContent>, CustomStringConvertible, Equatable, Hashable {
    
    /// page identifier
    public var identifier:String
    
    /// page parent identifier
    public var parent:String?
    
    /// collection of this page
    public var collection:AMPCollection
    
    /// last update date of this page
    public var lastUpdate:NSDate!
    
    /// locale code for the page
    public var locale:String

    /// layout identifier (name of the toplevel container outlet)
    public var layout:String
    
    /// content list
    public var content = [AMPContent]()

    /// set to true to avoid fetching from cache
    private var useCache = false

    /// CustomStringConvertible
    public var description: String {
        return "AMPPage: \(identifier), \(content.count) content items"
    }
    
    /// Hashable requirement
    public var hashValue: Int {
        return self.collection.hashValue + self.identifier.hashValue
    }
    
    // MARK: Initializer
    
    /// Initialize page for collection (uses cache, initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter layout: the page layout
    /// - Parameter callback: the block to call when initialization finished
    convenience init(collection: AMPCollection, identifier: String, layout: String, parent: String?, callback:(AMPPage -> Void)) {
        self.init(collection: collection, identifier:identifier, layout:layout, useCache: true, parent: parent, callback:callback)
    }
    
    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `AMPCollection`
    ///
    /// - Parameter collection: the collection this page belongs to
    /// - Parameter identifier: the page identifier
    /// - Parameter layout: the page layout
    /// - Parameter useCache: set to false to force a page refresh
    /// - Parameter callback: the block to call when initialization finished
    init(collection: AMPCollection, identifier: String, layout: String, useCache: Bool, parent: String?, callback:(AMPPage -> Void)) {
        // Full async initializer, self will be populated async
        self.identifier = identifier
        self.layout = layout
        self.collection = collection
        self.useCache = useCache
        self.parent = parent
        self.locale = self.collection.locale
        super.init()
        
        // fetch page async
        self.fetch(identifier) {
            self.isReady = true
            if self.content.count > 0 {
                if case let container as AMPContainerContent = self.content.first! {
                    self.layout = container.outlet
                }
            }
            for o in self.content {
                self.callCallbacks(o.outlet, value: o, error: nil)
            }
            
            let failedIdentifiers = self.getQueuedIdentifiers()
            for identifier in failedIdentifiers {
                self.callError(identifier, error: .OutletNotFound(identifier))
            }

            callback(self)
        }
    }
    
    // MARK: Async API
    
    /// Error handler to chain to the page
    ///
    /// - Parameter callback: the block to call in case of an error
    /// - Returns: self, to be able to chain more actions to the page
    public func onError(callback: (AMPError -> Void)) -> AMPPage {
        // enqueue error callback for lazy resolving
        if let original = AMP.getCachedPage(self.collection, identifier: self.identifier) {
            original.appendErrorCallback(callback)
        }
        return self
    }

    /// fetch page children
    ///
    /// - Parameter identifier: identifier of child page
    /// - Parameter callback: callback to call when child page is ready, will not be called on hierarchy errors
    /// - Returns: self, to be able to chain more actions to the page
    public func child(identifier: String, callback: (AMPPage -> Void)) -> AMPPage {
        AMP.collection(self.collection.identifier).page(identifier) { page in
            if page.parent == self.identifier {
                callback(page)
            } else {
                self.collection.callError(identifier, error: .InvalidPageHierarchy(parent: self.identifier, child: page.identifier))
            }
        }
        
        return self
    }

    /// fetch page children
    ///
    /// - Parameter identifier: identifier of child page
    /// - Returns: page object that resolves async or nil if page not child of self
    public func child(identifier: String) -> AMPPage? {
        let page = self.collection.page(identifier)
        if page.parent == self.identifier {
            return page
        }
        self.collection.callError(identifier, error: .InvalidPageHierarchy(parent: self.identifier, child: page.identifier))
        return nil
    }
    
    
    /// enumerate page children
    ///
    /// - Parameter callback: the callback to call for each child
    public func children(callback: (AMPPage -> Void)) {
        AMP.collection(self.collection.identifier) { collection in
            let children = collection.getChildIdentifiersForPage(self.identifier)
            for child in children {
                self.child(child, callback: callback)
            }
        }
    }
    
    
    /// override default error callback to bubble error up to collection
    override func defaultErrorCallback(error: AMPError) {
        self.collection.callError(self.identifier, error: error)
    }
    
    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - Parameter name: outlet name to fetch
    /// - Parameter callback: block to execute when outlet was found, will not be called if no such outlet
    ///                       exists or there was any kind of communication error while fetching the page
    /// - Returns: self to be able to chain another call
    public func outlet(name: String, callback: (AMPContent -> Void)) -> AMPPage {
        // resolve instantly if possible
        self.appendCallback(name, callback: callback)

        if self.isReady {
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
                self.callError(name, error: .OutletNotFound(name))
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
                self.callError(name, error: .OutletNotFound(name))
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
        // resolve instantly if possible
        self.appendCallback(name) { outlet in
            callback(true)
        }
        
        if self.isReady {
            // search content
            var found = false
            for content in self.content {
                if content.outlet == name {
                    found = true
                    break
                }
            }
            callback(found)
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
    
    /// Fetch page from cache or web
    ///
    /// - Parameter identifier: page identifier to get
    /// - Parameter callback: block to call when the fetch finished
    private func fetch(identifier: String, callback:(Void -> Void)) {
        AMPRequest.fetchJSON("pages/\(self.collection.identifier)/\(identifier)", queryParameters: [ "locale" : self.collection.locale ], cached:self.useCache) { result in
            if case .Failure = result {
                self.collection.callError(identifier, error: .PageNotFound(identifier))
                self.hasFailed = true
                return
            }

            // we need a result value and need it to be a dictionary
            guard result.value != nil,
                case .JSONDictionary(let dict) = result.value! else {
                    self.collection.callError(identifier, error: .JSONObjectExpected(result.value!))
                    self.hasFailed = true
                    return
            }
            
            // furthermore we need a page and a last_updated element
            guard dict["page"] != nil && dict["last_updated"] != nil,
                  case .JSONArray(let array) = dict["page"]!,
                  case .JSONNumber(let timestamp) = dict["last_updated"]! else {
                    self.collection.callError(identifier, error: .JSONObjectExpected(dict["page"]))
                    self.hasFailed = true
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
                        self.collection.callError(identifier, error: .InvalidJSON(result.value))
                        self.hasFailed = true
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
                        self.collection.callError(identifier, error: .JSONObjectExpected(translation))
                        self.hasFailed = true
                        return
                    }
                    
                    // make sure the translation contains all needed fields
                    guard (t["locale"] != nil) && (t["content"] != nil),
                        case .JSONString(let localeCode) = t["locale"]!,
                        case .JSONArray(let content)     = t["content"]! else {
                            self.collection.callError(identifier, error: .InvalidJSON(translation))
                            self.hasFailed = true
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

