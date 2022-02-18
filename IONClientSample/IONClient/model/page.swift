//
//  page.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation


/// Page class, contains functionality to fetch outlet content
internal class IONPage {

    /// Page identifier
    open var identifier: String

    /// Page parent identifier
    open var parent: String?

    /// Collection of this page
    open var collection: IONCollection

    /// Last update date of this page
    open var lastUpdate: Date?

    /// This instance produced an error while fetching from net
    open var hasFailed = false

    /// Locale code for the page
    open var locale: String

    /// Layout identifier (name of the toplevel container outlet)
    open var layout: String

    /// Content list
    open var content = [IONContent]()

    /// Page position
    open var position: Int = 0

    /// Metadata of the page
    open var metadata: IONPageMeta? {
        return self.collection.getPageMeta(identifier)
    }

    /// Set to true to avoid fetching from cache
    fileprivate var useCache = IONCacheBehaviour.prefer

    /// Page has loaded
    internal var isReady = false

    /// Internal lock
    internal var parentLock = NSLock()

    /// Work queue
    internal var workQueue: DispatchQueue

    /// Internal uuid
    internal var uuid = UUID().uuidString

    /// Internal identifier used to store the page into the `collection.pageCache`
    /// when using the `forkedWorkQueueWithCollection` initializer
    lazy internal var forkedIdentifier: String = {
        return "\(self.identifier)-\(self.uuid)"
    }()


    // MARK: Initializer

    /// Initialize page for collection (initializes real object)
    ///
    /// Use the `page` function from `IONCollection`
    ///
    /// - parameter collection: The collection this page belongs to
    /// - parameter identifier: The page identifier
    /// - parameter layout: The page layout
    /// - parameter cacheBehaviour: `.Prefer`: Loads the page from cache if no update is available.
    ///                             `.Force`:  Loads the page from cache.
    ///                             `.Ignore`: Loads the page from server.
    /// - parameter parent: The parent of the page (optional)
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides Result.Success containing an `IONPage` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    ///
    init(collection: IONCollection, identifier: String, layout: String?, cacheBehaviour: IONCacheBehaviour, parent: String?, callback: ((Result<IONPage, Error>) -> Void)?) {
        // Full asynchronous initializer, self will be populated asynchronously
        self.identifier = identifier
        self.workQueue = DispatchQueue(label: "com.anfema.ion.page.\(identifier)", attributes: [])
        self.layout = layout ?? "unknown"
        self.collection = collection
        self.useCache = cacheBehaviour
        self.parent = parent
        self.locale = self.collection.locale

        // dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        self.workQueue.async(flags: .barrier, execute: {
            self.parentLock.lock()
            let semaphore = DispatchSemaphore(value: 0)

            self.fetch(usingPageIdentifier: identifier) { error in
                if let error = error {
                    // set error state, this forces all blocks in the work queue to cancel themselves
                    self.hasFailed = true
                    responseQueueCallback(callback, parameter: .failure(error))
                    semaphore.signal()

                } else {
                    guard let pageMeta = self.collection.getPageMeta(identifier) else {
                        self.hasFailed = true
                        responseQueueCallback(callback, parameter: .failure(IONError.pageNotFound(collection: collection.identifier, page: identifier)))
                        semaphore.signal()
                        return
                    }

                    if let lastUpdate = self.lastUpdate, lastUpdate.compare(pageMeta.lastChanged) != .orderedSame {
                        self.useCache = .ignore
                        self.content.removeAll()

                        self.fetch(usingPageIdentifier: identifier) { error in
                            if let error = error {
                                self.hasFailed = true
                                responseQueueCallback(callback, parameter: .failure(error))
                                semaphore.signal()
                            } else {
                                self.isReady = true
                                responseQueueCallback(callback, parameter: .success(self))
                                semaphore.signal()
                            }
                        }
                    } else {
                        self.isReady = true
                        responseQueueCallback(callback, parameter: .success(self))
                        semaphore.signal()
                    }
                }
            }

            _ = semaphore.wait(timeout: DispatchTime.distantFuture)
            self.parentLock.unlock()
        })

        self.collection.pageCache[identifier] = self
    }


    // MARK: - API

    /// Fork the work queue, the returning page has to be finished or canceled, else you risk a memory leak
    ///
    /// - returns: `self` with new work queue that is cancelable
    open func cancelable() -> CancelableIONPage {
        return CancelableIONPage(page: self)
    }


    /// Callback when page fully loaded
    ///
    /// - parameter callback: Callback to call
    /// - returns: self for chaining
    @discardableResult open func waitUntilReady(_ callback: @escaping ((Result<IONPage, Error>) -> Void)) -> IONPage {
        workQueue.async {
            guard !self.hasFailed else {
                responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                return
            }

            responseQueueCallback(callback, parameter: .success(self))
        }

        return self
    }


    /// Callback when page work queue is empty
    ///
    /// Attention: This blocks all queries that follow this call until the callback
    /// has completed
    ///
    /// - parameter callback: callback to call
    /// - returns: `self` for chaining
    @discardableResult open func onCompletion(_ callback: @escaping ((_ page: IONPage, _ completed: Bool) -> Void)) -> IONPage {
        workQueue.async(flags: .barrier, execute: {
            responseQueueCallback(callback, parameter: (page: self, completed: !self.hasFailed))
        })

        return self
    }


    /// Fetch an outlet by name (from loaded page)
    ///
    /// - parameter name: Outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - returns: Result.Success containing an `IONContent` if the outlet is valid
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
    open func outlet(_ name: String, atPosition position: Int = 0) -> Result<IONContent, Error> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a page loading asynchronously
            return .failure(IONError.didFail)
        }

        // search for content with the named outlet and specified position
        guard let cObj = self.content.filter({ $0.outlet == name && $0.position == position }).first else {
            return .failure(IONError.outletNotFound(name))
        }

        return .success(cObj)
    }


    /// Fetch an outlet by name (probably deferred by page loading)
    ///
    /// - parameter name: Outlet name to fetch
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the outlet becomes available.
    ///                       Provides `Result.Success` containing an `IONContent` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: `self` to be able to chain another call
    @discardableResult open func outlet(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<IONContent, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.outlet(name, atPosition: position))
        }

        return self
    }


    /// Check if an Outlet exists
    ///
    /// - parameter name: Outlet to check
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `Bool` if the page becomes available
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    open func outletExists(_ name: String, atPosition position: Int = 0) -> Result<Bool, Error> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a page loading asynchronously
            return .failure(IONError.didFail)
        }

        // search first occurrence of content with the named outlet and specified position
        if self.content.first(where: { $0.outlet == name && $0.position == position }) != nil {
            return .success(true)
        }

        return .success(false)
    }


    /// Check if an Outlet exists
    ///
    /// - parameter name: Outlet to check
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the page becomes available.
    ///                       Provides `Result.Success` containing a `Bool` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: `self` for chaining
    @discardableResult open func outletExists(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<Bool, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.outletExists(name, atPosition: position))
        }

        return self
    }

    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name:     outlet to check
    /// - parameter callback: callback with object count
    ///
    /// - returns: `self` for chaining
    @discardableResult open func numberOfContentsForOutlet(_ name: String, callback: @escaping ((Result<Int, Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.numberOfContentsForOutlet(name))
        }

        return self
    }

    /// Number of contents for an outlet (if outlet is an array)
    ///
    /// - parameter name: outlet to check
    ///
    /// - returns: count if page was ready, `nil` if page is not loaded
    open func numberOfContentsForOutlet(_ name: String) -> Result<Int, Error> {
        guard self.isReady && self.hasFailed == false else {
            // cannot return outlet synchronously from a async loading page
            return .failure(IONError.didFail)
        }

        // search content
        return .success(self.content.filter({ $0.outlet == name }).count)
    }

    // MARK: Private

    fileprivate init(forkedWorkQueueWithCollection collection: IONCollection, identifier: String, locale: String) {
        self.identifier = identifier
        self.workQueue = DispatchQueue(label: "com.anfema.ion.page.\(identifier).fork.\(Date().timeIntervalSince1970)", attributes: [])
        self.locale = locale
        self.useCache = .prefer
        self.collection = collection
        self.layout = ""

        // FIXME: How to remove this from the collection cache again?
        self.collection.pageCache[self.forkedIdentifier] = self
    }


    /// Fetch page from cache or web
    ///
    /// - parameter identifier: Page identifier to get
    /// - parameter callback: Block to call when the fetch finished
    fileprivate func fetch(usingPageIdentifier identifier: String, callback: @escaping ((IONError?) -> Void)) {
        IONRequest.fetchJSON(fromEndpoint: "\(self.collection.locale)/\(self.collection.identifier)/\(identifier)", queryParameters: ["variation": ION.config.variation ], cacheBehaviour: ION.config.cacheBehaviour(self.useCache)) { result in

            guard case .success(let resultValue) = result else {
                if let error = result.error, case IONError.notAuthorized = error {
                    callback(.notAuthorized)
                } else {
                    callback(.pageNotFound(collection: self.collection.identifier, page: identifier))
                }

                return nil
            }

            // We need a result value and need it to be a dictionary
            guard case .jsonDictionary(let dict) = resultValue else {
                callback(.jsonObjectExpected(resultValue))
                return nil
            }

            // Furthermore we need a page and a last_updated element
            guard let rawPage = dict["page"], dict["last_updated"] != nil,
                case .jsonArray(let array) = rawPage else {
                    callback(.jsonObjectExpected(dict["page"]))
                    return nil
            }

            // If we have a nonzero result
            if let firstElement = array.first, case .jsonDictionary(let dict) = firstElement {
                // Make sure everything is there
                guard let rawIdentifier     = dict["identifier"],
                    let rawContents         = dict["contents"],
                    let rawLastChanged      = dict["last_changed"],
                    let parent              = dict["parent"],
                    let rawLocale           = dict["locale"],
                    case .jsonString(let id) = rawIdentifier,
                    case .jsonArray(let contents) = rawContents,
                    case .jsonString(let last_changed) = rawLastChanged,
                    case .jsonString(let locale) = rawLocale else {
                        callback(.invalidJSON(resultValue))
                        return nil
                }

                if case .jsonString(let parentID) = parent {
                    self.parent = parentID
                } else {
                    self.parent = nil
                }

                self.identifier = id
                self.locale = locale
                self.lastUpdate = .makeFrom(isoDateString: last_changed)

                for contentJSON in contents {

                    guard let content = try? IONContent.factory(json: contentJSON) else {
                        if ION.config.loggingEnabled {
                            print("ION: Skipping content due to failed deserialization: \(contentJSON)")
                        }
                        continue
                    }

                    // By default ION wrapps all content in a single container at root level
                    // The content is a container and number of contents is 1
                    if case let container as IONContainerContent = content, contents.count == 1 {
                        // Append all toplevel content of the container
                        for child in container.children {
                            self.content.append(child)
                        }
                    }
                    // In all other cases append content directly
                    // Should not occur in default ION environments
                    else {
                        self.content.append(content)
                    }
                }
            }

            // Reset to using cache
            self.useCache = .prefer

            // All finished, call block
            callback(nil)

            return self.lastUpdate
        }
    }
}

/// Cancelable page, either finish processing with `finish()` or cancel with `cancel()`. Will leak if not done so.
internal class CancelableIONPage: IONPage {

    init(page: IONPage) {
        super.init(forkedWorkQueueWithCollection: page.collection, identifier: page.identifier, locale: page.locale)

        // Dispatch barrier block into work queue, this sets the queue to standby until the fetch is complete
        self.workQueue.async(flags: .barrier, execute: {
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
        })
    }

    /// Cancel all pending requests for this page
    open func cancel() {
        self.workQueue.async(flags: .barrier, execute: {
            self.hasFailed = true
            self.finish()
        })
    }

    /// Finish all requests and discard page
    open func finish() {
        self.workQueue.async(flags: .barrier, execute: {
            self.collection.pageCache.removeValue(forKey: self.forkedIdentifier)
        })
    }
}
