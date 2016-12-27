//
//  collection.swift
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


/// Collection class, contains pages, has functionality to asynchronously fetch data
open class IONCollection {

    /// Identifier
    open var identifier: String

    /// Locale code
    open var locale: String

    /// Default locale for this collection
    open var defaultLocale: String?

    /// Last update date
    open var lastUpdate: Date?

    /// Last change date on server
    open var lastChanged: Date?

    /// This instance produced an error while fetching from net
    open var hasFailed: Bool = false

    /// Page metadata
    internal var pageMeta = [IONPageMeta]()

    /// Memory cache for pages
    internal var pageCache = [String: IONPage]()

    /// Internal lock
    internal var parentLock = NSLock()

    /// Work queue
    internal var workQueue: DispatchQueue

    /// Set to false to avoid using the cache (refreshes, etc.)
    fileprivate var useCache = IONCacheBehaviour.prefer

    /// Block to call on completion
    fileprivate var completionBlock: ((_ collection: Result<IONCollection>, _ completed: Bool) -> Void)?

    /// Archive download url
    internal var archiveURL: String?

    /// FTS download url
    internal var ftsDownloadURL: String?

    /// Internal id
    internal var uuid = UUID().uuidString

    /// Internal identifier used to store the collection into the `ION.collectionCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()


    // MARK: - Initializer

    /// Initialize collection async
    ///
    /// use `collection` method of `ION` class instead!
    ///
    /// - parameter identifier: The collection identifier
    /// - parameter locale: Locale code to fetch
    /// - parameter useCache: `.Prefer`: Loads the collection from cache if no update is available.
    ///                       `.Force`:  Loads the collection from cache.
    ///                       `.Ignore`: Loads the collection from server.
    /// - parameter callback: Block to call when the collection becomes available.
    ///                       Provides Result.Success containing an `IONCollection` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    init(identifier: String, locale: String, useCache: IONCacheBehaviour, callback: ((Result<IONCollection>) -> Void)?) {
        self.identifier = identifier
        self.workQueue = DispatchQueue(label: "com.anfema.ion.collection.\(identifier)", attributes: [])
        self.locale = locale
        self.useCache = useCache

        // Dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        self.workQueue.async(flags: .barrier, execute: {
            self.parentLock.lock()
            let semaphore = DispatchSemaphore(value: 0)

            self.fetch(identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    responseQueueCallback(callback, parameter: .failure(error))
                    self.hasFailed = true
                } else {
                    ION.collectionCache[identifier] = self
                    responseQueueCallback(callback, parameter: .success(self))
                }

                semaphore.signal()
            }

            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            self.parentLock.unlock()
        }) 
    }


    // MARK: - API

    /// Fetch a page from this collection
    ///
    /// - parameter identifier: Page identifier
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides Result.Success containing an `IONPage` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    /// - returns: self, to be able to chain more actions to the collection
    @discardableResult open func page(_ identifier: String, callback: @escaping ((Result<IONPage>) -> Void)) -> IONCollection {
        self.workQueue.async {
            guard !self.hasFailed else {
                return
            }

            if let page = self.pageCache[identifier] {
                if page.isReady {
                    if self.checkNeedsUpdate(page) {
                        self.update(page, callback: { result in
                            // return cached page if update failed
                            guard case .success(let updatedPage) = result else {
                                responseQueueCallback(callback, parameter: .success(page))
                                return
                            }

                            // return updated page
                            responseQueueCallback(callback, parameter: .success(updatedPage))
                        })
                    } else {
                        ION.config.responseQueue.async {
                            callback(.success(page))

                            self.workQueue.async(flags: .barrier, execute: {
                                self.checkCompleted()
                            }) 
                        }
                    }
                } else {
                    page.workQueue.async {
                        guard !self.hasFailed else {
                            return
                        }

                        if self.checkNeedsUpdate(page) {
                            self.update(page, callback: callback)
                        } else {
                            ION.config.responseQueue.async {
                                callback(.success(page))

                                self.workQueue.async(flags: .barrier, execute: {
                                    self.checkCompleted()
                                }) 
                            }
                        }
                    }
                }
            } else {
                guard let meta = self.getPageMetaForPage(identifier) else {
                    responseQueueCallback(callback, parameter: .failure(IONError.pageNotFound(identifier)))
                    return
                }

                self.pageCache[identifier] = IONPage(collection: self, identifier: identifier, layout: meta.layout, useCache: .prefer, parent: meta.parent) { result in
                    guard case .success(let page) = result else {
                        responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                        return
                    }

                    page.position = meta.position

                    // recursive call to use update check from "page is caches" path
                    self.page(identifier) { page in
                        callback(page)
                    }
                }
            }
        }

        // allow further chaining
        return self
    }


    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves asynchronously once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter identifier: Page identifier
    /// - returns: A `IONPage` that resolves automatically if the underlying page becomes available, nil if page unknown
    open func page(_ identifier: String) -> IONPage {

        if let page = self.pageCache[identifier] {
            // well page is cached, just return cached version
            if page.isReady {
                if self.checkNeedsUpdate(page) {
                    return self.update(page, callback: nil) ?? page
                } else {
                    return page
                }
            }
        }

        // search metadata
        var layout: String? = nil
        var parent: String? = nil
        var position: Int = 0

        if let meta = self.getPageMetaForPage(identifier) {
            layout = meta.layout
            parent = meta.parent
            position = meta.position
        }

        // not cached, fetch from web and add it to the cache
        let page = IONPage(collection: self, identifier: identifier, layout: layout, useCache: .prefer, parent: parent) { page in
            self.workQueue.async(flags: .barrier, execute: {
                self.checkCompleted()
            }) 
        }

        page.position = position
        self.pageCache[identifier] = page

        return page
    }


    /// Fetch a page from this collection
    ///
    /// As there is no callback, this returns a page that resolves asynchronously once the page becomes available
    /// all actions chained to the page will be queued until the data is available
    ///
    /// - parameter index: Position of the page in the collection
    /// - returns: A page that resolves automatically if the underlying page becomes available, nil if page unknown
    open func page(_ index: Int) -> IONPage? {
        guard index > 0 else {
            return nil
        }

        let pages = self.pageMeta.filter({ $0.parent == nil }).sorted(by: { $0.0.position < $0.1.position })

        guard pages.isEmpty == false && index < pages.count else {
            return nil
        }

        return page(pages[index].identifier)
    }


    /// Enumerate pages
    ///
    /// - parameter callback: Block to call for each page
    /// - returns: self for chaining
    @discardableResult open func pages(_ callback: @escaping ((Result<IONPage>) -> Void)) -> IONCollection {
        // append page listing to work queue
        self.workQueue.async {
            guard !self.hasFailed else {
                return
            }

            // only pages where no parent is set will be returned (top level)
            for meta in self.pageMeta where meta.parent == nil {
                self.page(meta.identifier, callback: callback)
            }
        }

        return self
    }

    /// Fork the work queue, the returning collection has to be finished or canceled, else you risk a memory leak
    ///
    /// - returns: self with new work queue that is cancelable
    open func cancelable() -> CancelableIONCollection {
        return CancelableIONCollection(collection: self)
    }

    /// Callback when collection fully loaded
    ///
    /// - parameter callback: Callback to call
    /// - returns: self for chaining
    @discardableResult open func waitUntilReady(_ callback: @escaping ((Result<IONCollection>) -> Void)) -> IONCollection {
        self.workQueue.async {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            responseQueueCallback(callback, parameter: .success(self))
        }

        return self
    }


    /// Callback when collection work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed, the callback will only be called if the collection fetches any page,
    /// it will not fire when no other actions than loading the collection itself occur.
    ///
    /// - parameter callback: Callback to call
    /// - returns: self for chaining
    @discardableResult open func onCompletion(_ callback: @escaping ((_ collection: Result<IONCollection>, _ completed: Bool) -> Void)) -> IONCollection {
        self.workQueue.async(flags: .barrier, execute: {
            self.completionBlock = callback
        }) 

        return self
    }


    // MARK: - Private

    fileprivate func checkNeedsUpdate(_ page: IONPage) -> Bool {
        // ready, check if we need to update
        if page.hasFailed {
            return true
        } else {
            if let meta = self.getPageMetaForPage(page.identifier) {
                if let lastUpdate = page.lastUpdate, lastUpdate.compare(meta.lastChanged) == ComparisonResult.orderedAscending {
                    // page out of date, force update
                    return true
                }
            }
        }

        return false
    }


    @discardableResult fileprivate func update(_ page: IONPage, callback: ((Result<IONPage>) -> Void)?) -> IONPage? {
        // fetch page update
        guard let meta = self.getPageMetaForPage(page.identifier) else {
            return nil
        }

        self.pageCache[identifier] = IONPage(collection: self, identifier: page.identifier, layout: meta.layout, useCache: .ignore, parent: meta.parent) { result in
            guard case .success(let page) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            page.position = meta.position

            responseQueueCallback(callback, parameter: .success(page))

            page.onCompletion { _, _ in
                self.checkCompleted()
            }
        }

        return self.pageCache[identifier]
    }


    fileprivate func checkCompleted() {
        self.workQueue.async(flags: .barrier, execute: {
            var completed = true

            for (_, page) in self.pageCache {
                if !page.isReady && !page.hasFailed {
                    completed = false
                    break
                }
            }

            guard let completionBlock = self.completionBlock, completed == true else {
                return
            }

            self.completionBlock = nil

            ION.config.responseQueue.async {
                completionBlock(.success(self), !self.hasFailed)
            }
        }) 
    }


    fileprivate init(forkedWorkQueueWithIdentifier identifier: String, locale: String) {
        self.locale = locale
        self.useCache = .prefer
        self.identifier = identifier
        self.workQueue = DispatchQueue(label: "com.anfema.ion.collection.\(identifier).forked.\(Date().timeIntervalSince1970)", attributes: [])

        // FIXME: How to remove this from the collection cache again?
        ION.collectionCache[self.forkedIdentifier] = self
    }


    /// Fetch collection from cache or web
    ///
    /// - parameter identifier: collection identifier to get
    /// - parameter callback: block to call when the fetch finished
    fileprivate func fetch(_ identifier: String, callback: @escaping ((IONError?) -> Void)) {
        IONRequest.fetchJSON(fromEndpoint: "\(self.locale)/\(identifier)", queryParameters: ["variation": ION.config.variation ], cacheBehaviour: self.useCache) { result in

            guard case .success(let resultValue) = result else {
                if let error = result.error, case IONError.notAuthorized = error {
                    callback(.notAuthorized)
                } else {
                    callback(IONError.collectionNotFound(identifier))
                }

                return nil
            }

            // we need a result value and need it to be a dictionary
            guard case .jsonDictionary(let dict) = resultValue else {
                callback(.jsonObjectExpected(resultValue))
                return nil
            }

            // furthermore we need a collection and a last_updated element
            guard let rawCollection = dict["collection"], let rawLastUpdated = dict["last_updated"],
                case .jsonArray(let array)      = rawCollection,
                case .jsonNumber(let timestamp) = rawLastUpdated else {
                    callback(.jsonObjectExpected(resultValue))
                    return nil
            }

            self.lastUpdate = Date(timeIntervalSince1970: timestamp)

            // if we have a nonzero result
            if let firstItem = array.first, case .jsonDictionary(let dict) = firstItem {

                // make sure everything is there
                guard let rawIdentifier     = dict["identifier"],
                    let rawPages            = dict["pages"],
                    let rawDefaultLocale    = dict["default_locale"],
                    let rawArchive          = dict["archive"],
                    let rawFTSdb            = dict["fts_db"],
                    case .jsonString(let id)             = rawIdentifier,
                    case .jsonString(let defaultLocale)  = rawDefaultLocale,
                    case .jsonString(let archiveURL)     = rawArchive,
                    case .jsonArray(let pages)           = rawPages else {
                        callback(.invalidJSON(resultValue))
                        return nil
                }

                // initialize self
                self.identifier = id
                self.defaultLocale = defaultLocale
                self.archiveURL = archiveURL

                if case .jsonString(let ftsURL) = rawFTSdb {
                    self.ftsDownloadURL = ftsURL
                }

                // extract last change date from collection, default to last update when not available
                self.lastChanged = self.lastUpdate

                if let rawLastChanged = dict["last_changed"] {
                    if case .jsonString(let lastChanged) = rawLastChanged {
                        self.lastChanged = NSDate(isoDateString: lastChanged) as? Date
                        self.lastUpdate = self.lastChanged
                    }
                }

                // initialize page metadata objects from the collection's page array
                for page in pages {
                    do {
                        let obj = try IONPageMeta(json: page, position: 0, collection: self)

                        // find max position for current parent
                        var position = -1

                        for page in self.pageMeta where page.parent == obj.parent {
                            if page.position > position {
                                position = page.position
                            }
                        }

                        obj.position = position + 1

                        self.pageMeta.append(obj)
                    } catch {
                        if let json = JSONEncoder(page).prettyJSONString {
                            if ION.config.loggingEnabled {
                                print("Invalid page: " + json)
                            }
                        } else {
                            if ION.config.loggingEnabled {
                                print("Invalid page, invalid json")
                            }
                        }
                    }
                }
            }

            // revert to using cache
            self.useCache = .prefer

            // all finished, call callback
            callback(nil)

            return self.lastChanged
        }
    }
}


extension IONCollection {

    /// Checks if the collection and 'otherCollection' have the same content.
    ///
    /// - parameter otherCollection: The collection you want to check for equal content.
    /// - returns: `true` if both collections have the same content - `false` if they have different content.
    public func equals(_ otherCollection: IONCollection) -> Bool {
        var collectionChanged = false

        // compare metadata count
        if (self.pageMeta.count != otherCollection.pageMeta.count) || (self.lastChanged != otherCollection.lastChanged) {
            collectionChanged = true
        } else {
            // compare old collection and new collection page change dates and identifiers
            for i in 0..<self.pageMeta.count {
                let c1 = self.pageMeta[i]
                let c2 = otherCollection.pageMeta[i]

                if c1.identifier != c2.identifier || c1.lastChanged.compare(c2.lastChanged as Date) != .orderedSame {
                    collectionChanged = true
                    break
                }
            }
        }

        return collectionChanged == false
    }
}


/// Cancelable collection, remove from memory by calling either `cancel()` or `finish()`. Will leak if not done!
open class CancelableIONCollection: IONCollection {

    init(collection: IONCollection) {
        super.init(forkedWorkQueueWithIdentifier: collection.identifier, locale: collection.locale)

        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        self.workQueue.async(flags: .barrier, execute: {
            collection.parentLock.lock()

            self.identifier = collection.identifier
            self.locale = collection.locale
            self.defaultLocale = collection.defaultLocale
            self.lastUpdate = collection.lastUpdate
            self.pageMeta = collection.pageMeta
            self.hasFailed = collection.hasFailed

            collection.parentLock.unlock()

            self.checkCompleted()
        }) 
    }

    /// Cancel all requests queued for a collection
    open func cancel() {
        self.workQueue.async(flags: .barrier, execute: {
            // cancel all page loads

            // TODO: Test cancelling of page loads, needs support in mock framework
            for (_, page) in self.pageCache {
                if case let p as CancelableIONPage = page {
                    p.cancel()
                }
            }

            // set ourselves to failed to cancel all queued items
            self.hasFailed = true

            // remove self from cache
            self.finish()
        }) 
    }

    /// Finish the processing and discard the collection
    open func finish() {
        self.workQueue.async(flags: .barrier, execute: {
            self.pageCache.removeAll() // break cycle
            ION.collectionCache.removeValue(forKey: self.forkedIdentifier)
        }) 
    }
}
