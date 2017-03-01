//
//  ion.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Markdown

/// ION base class, use all ION functionality by using this object's class methods
open class ION {
    /// ION configuration, be sure to set up before using any ION calls or risk a crash!
    static open var config = IONConfig()

    /// Internal cache for collections
    static internal var collectionCache = [String: IONCollection]()

    /// Pending downloads
    static internal var pendingDownloads = [String: (totalBytes: Int64, downloadedBytes: Int64)]()

    /// Login user
    ///
    /// - parameter username: the username to log in
    /// - parameter password: the password to send
    /// - parameter callback: block to call when login request finished (Bool parameter is success flag)
    open class func login(withUsername username: String, password: String, callback: @escaping ((Bool) -> Void)) {
        IONRequest.postJSON(toEndpoint: "login", queryParameters: nil, body: [
            "login": [
                "username": username,
                "password": password
            ]
        ]) { result in
            guard result.isSuccess,
                  let jsonResponse = result.value,
                  let json = jsonResponse.json,
                  case .jsonDictionary(let dict) = json,
                  let rawLogin = dict["login"],
                  case .jsonDictionary(let loginDict) = rawLogin,
                  let rawToken = loginDict["token"],
                  case .jsonString(let token) = rawToken else {

                self.config.sessionToken = nil
                responseQueueCallback(callback, parameter: false)

                return
            }

            self.config.sessionToken = token
            responseQueueCallback(callback, parameter: true)
        }
    }

    /// Fetch a collection sync
    ///
    /// If the collection is not in any cache initialization of values may
    /// be delayed. Access to items in a non initialized collection may have
    /// undefined results
    ///
    /// - parameter identifier: the identifier of the collection
    /// - returns: collection object from cache or empty collection object
    open class func collection(_ identifier: String) -> IONCollection {
        let cachedCollection = self.collectionCache[identifier]
        
        // return memcache if not timed out
        if !self.hasCacheTimedOut(collection: identifier) {
            if let cachedCollection = cachedCollection {
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValue(forKey: identifier)
        }

        // try an online update
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(collection: identifier)) ? .ignore : .prefer)
        let newCollection = IONCollection(
            identifier: identifier,
            locale: ION.config.locale,
            cacheBehaviour: cache
        ) { result in
            guard let cachedCollection = cachedCollection, !cachedCollection.hasFailed,
                  case .success(let collection) = result else {
                    // FIXME: What happens in error case?
                return
            }

            self.notifyForUpdates(collection, collection2: cachedCollection)
        }

        if self.hasCacheTimedOut(collection: identifier) {
            self.config.lastOnlineUpdate[identifier] = Date()
        }

        return newCollection
    }

    /// Fetch a collection and call block on finish
    ///
    /// - parameter identifier: the identifier of the collection
    /// - parameter callback: the block to call when the collection is fully initialized
    /// - returns: fetched collection to be able to chain calls
    @discardableResult open class func collection(_ identifier: String, callback: @escaping ((Result<IONCollection>) -> Void)) -> IONCollection {
        let cachedCollection = self.collectionCache[identifier]

        // return memcache if not timed out
        if !self.hasCacheTimedOut(collection: identifier) {
            if let cachedCollection = cachedCollection {
                if cachedCollection.hasFailed {
                    responseQueueCallback(callback, parameter: .failure(IONError.collectionNotFound(identifier)))
                } else {
                    responseQueueCallback(callback, parameter: .success(cachedCollection))
                }
                return cachedCollection
            }
        } else {
            // remove from mem cache if expired
            self.collectionCache.removeValue(forKey: identifier)
        }

        // try an online update
        let cache = ION.config.cacheBehaviour((self.hasCacheTimedOut(collection: identifier)) ? .ignore : .prefer)
        let newCollection = IONCollection(identifier: identifier, locale: ION.config.locale, cacheBehaviour: cache) { result in
            guard case .success(let collection) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }

            responseQueueCallback(callback, parameter: .success(collection))

            guard let cachedCollection = cachedCollection, !cachedCollection.hasFailed else {
                return
            }
            self.notifyForUpdates(collection, collection2: cachedCollection)
        }

        if self.hasCacheTimedOut(collection: identifier) {
            self.config.lastOnlineUpdate[identifier] = Date()
        }

        return newCollection
    }

    // MARK: - Internal

    /// Downloader calls this function to register a progress item with the global progress toolbar
    ///
    /// - parameter bytesReceived: Number of received bytes
    /// - parameter bytesExpected: Number of total expected bytes
    /// - parameter urlString: The URL of the file the progress should be reported
    ///
    class func registerProgress(bytesReceived: Int64, bytesExpected: Int64, urlString: String) {
        self.pendingDownloads[urlString] = (totalBytes: bytesExpected, downloadedBytes: bytesReceived)

        // sum up all pending downloads
        var totalBytes: Int64 = 0
        var downloadedBytes: Int64 = 0

        for (total, downloaded) in self.pendingDownloads.values {
            totalBytes += total
            downloadedBytes += downloaded
        }

        // call progress handler
        if let progressHandler = ION.config.progressHandler {
            let count = self.pendingDownloads.count
            ION.config.responseQueue.async {
                progressHandler(totalBytes, downloadedBytes, count)
            }
        }

        // remove from pending when total == downloaded
        if bytesReceived == bytesExpected {
            self.pendingDownloads.removeValue(forKey: urlString)
            if let progressHandler = ION.config.progressHandler, self.pendingDownloads.isEmpty {
                ION.config.responseQueue.async {
                    progressHandler(0, 0, 0)
                }
            }
        }
    }

    // MARK: - Private

    /// Call all update notification blocks
    ///
    /// - parameter collectionIdentifier: collection id to send to update block
    fileprivate class func callUpdateBlocks(withCollection collectionIdentifier: String) {
        for block in ION.config.updateBlocks.values {
            ION.config.responseQueue.async {
                block(collectionIdentifier)
            }
        }
    }

    /// Check if collection changed and send change notifications
    ///
    /// - parameter collection1: first collection
    /// - parameter collection2: second collection
    fileprivate class func notifyForUpdates(_ collection1: IONCollection, collection2: IONCollection) {
        if collection1.equals(to: collection2) == false {
            // call change blocks
            ION.callUpdateBlocks(withCollection: collection1.identifier)
        }
    }

    /// Init is private because only class functions should be used
    fileprivate init() {}
}


/// The loading option when requesting Page objects
public enum PageLoadingOption {
    /// Only the metadata of a page will be loaded
    case meta
    
    /// The full content of page will be loaded except media, files and images
    case full
}


public extension ION
{
    /// Represents a page identifier (should match a page defined in ion desk)
    public typealias PageIdentifier       = String
    
    /// Represents a collection identifier (should match a collection defined in ion desk)
    public typealias CollectionIdentifier = String
    
    /// Represents an outlet identifier (should match an outlet defined in ion desk)
    public typealias OutletIdentifier    = String
    
    /// Represents the position within content or page hierarchy
    public typealias Postion              = Int
    
    
    /// The default identifier of a collection that should be used within the application.
    /// If you define it, you can omit the collection identifier when requesting Pages.
    static var defaultCollectionIdentifier: String?
    
    
    /// Creates an operation to request a Page based on a given identifier within the specified collection.
    /// Add an onSuccess and/or an onFailure handler to the operation.
    /// It also allows you to specify the loading option of the Page.
    /// - parameter pageIdentifier: The identifier of the page that should be requested
    /// - parameter collectionIdentifier: The identifier of the collection the page is contained in (optional)
    /// - parameter option: The page loading option (full or meta)
    /// - returns: A AsyncResult object you can attach a success handler (.onSuccess) and optional a failure handler (.onFailure) to
    static public func page(pageIdentifier: PageIdentifier,
                            in collectionIdentifier: CollectionIdentifier? = nil,
                            option: PageLoadingOption = .meta) -> AsyncResult<Page> {
        
        let asyncResult = AsyncResult<Page>()
        
        ION.collection(validatedCollectionIdentifier(collectionIdentifier)) { result in
            guard case .success(let collection) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            let metaResult = collection.metadata(pageIdentifier)
            guard case .success(let metaData) = metaResult else {
                asyncResult.execute(result: .failure(metaResult.error ?? IONError.didFail))
                return
            }
            
            if option == .meta {
                let page = Page(metaData: metaData, fullData: nil)
                asyncResult.execute(result: .success(page))
            } else if option == .full {
                collection.page(pageIdentifier, callback: { result in
                    guard case .success(let fullPage) = result else {
                        asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                        return
                    }
                    
                    let page = Page(metaData: metaData, fullData: fullPage)
                    asyncResult.execute(result: .success(page))
                })
            } else {
                fatalError("not implemented")
            }
        }
        
        return asyncResult
    }
    
    
    /// Creates an operation to request the top level pages (not full loaded) within the specified collection.
    /// Add an onSuccess and/or an onFailure handler to the operation.
    ///
    /// __Warning__: The list of top level pages are not full loaded
    ///
    /// - parameter collectionIdentifier: The identifier of the collection the pages are contained in (optional)
    /// - returns: A AsyncResult object you can attach a success handler (.onSuccess) and optional a failure handler (.onFailure) to
    static public func topLevelPages(in collectionIdentifier: CollectionIdentifier? = nil) -> AsyncResult<[Page]> {
        
        let asyncResult = AsyncResult<[Page]>()
        
        ION.collection(validatedCollectionIdentifier(collectionIdentifier)) { result in
            guard case .success(let collection) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            let metaDataListResult = collection.childMetadataList(forParent: nil)
            guard case .success(let metaDataList) = metaDataListResult else {
                asyncResult.execute(result: .failure(metaDataListResult.error ?? IONError.didFail))
                return
            }
            
            asyncResult.execute(result: .success(metaDataList.map({Page(metaData: $0)})))
        }
        
        return asyncResult
    }
    
    
    /// Creates an operation to request a parent->child path for a given page identifier within a specific collection (optional).
    /// Requests a list of (not full loaded) page items (last item is current page, first item is toplevel parent).
    /// Add an onSuccess and/or an onFailure handler to the operation.
    /// - parameter pageIdentifier: The identifier of the page the path should be requested for
    /// - parameter collectionIdentifier: The identifier of the collection the page is contained in (optional)
    ///
    /// __Warning__: The list of pages within the path are not full loaded
    static public func path(for pageIdentifier: PageIdentifier,
                            in collectionIdentifier : CollectionIdentifier) -> AsyncResult<[Page]> {
        
        let asyncResult = AsyncResult<[Page]>()
        
        let validCollection = validatedCollectionIdentifier(collectionIdentifier)
        ION.collection(validCollection) { result in
            guard case .success(let collection) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            guard let path = collection.metaPath(pageIdentifier) else {
                asyncResult.execute(result: .failure(IONError.pageNotFound(collection: validCollection, page: pageIdentifier)))
                return
            }
            
            
            asyncResult.execute(result: .success(path.map({Page(metaData: $0)})))
        }
        
        return asyncResult
    }
    
    
    /// Instantiates a collection download taking an optional collection identifier into account.
    /// Add an onSuccess and/or an onFailure handler to the operation.
    /// - parameter collectionIdentifier: Identifier of the collection that should be downloaded
    static public func downloadCollection(_ collectionIdentifier: CollectionIdentifier? = nil) -> AsyncResult<Bool>
    {
        let asyncResult = AsyncResult<Bool>()
        
        ION.collection(validatedCollectionIdentifier(collectionIdentifier)).download { (success) in
            guard success == true else {
                asyncResult.execute(result: .failure(IONError.didFail))
                return
            }
            
            asyncResult.execute(result: .success(true))
        }
        
        return asyncResult
    }
    
    
    /// Requests a fulltext search handle for a given collection identifier
    /// Add an onSuccess and/or an onFailure handler to the operation.
    /// - parameter collectionIdentifier: Identifier of the collection a search handle should be returned for
    static public func searchHandle(for collectionIdentifier: CollectionIdentifier) -> AsyncResult<IONSearchHandle>
    {
        let asyncResult = AsyncResult<IONSearchHandle>()
        
        ION.collection(validatedCollectionIdentifier(collectionIdentifier)) { (result) in
            guard case .success(let collection) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            collection.getSearchHandle({ (result) in
                guard case .success(let searchHandle) = result else {
                    asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                    return
                }
                
                asyncResult.execute(result: .success(searchHandle))
            })
        }
        
        return asyncResult
    }
    
    
    static private func validatedCollectionIdentifier(_ collectionIdentifier: String?) -> String {
        
        if let collectionIdentifier = collectionIdentifier {
            return collectionIdentifier
        }
        else if let collectionIdentifier = defaultCollectionIdentifier {
            return collectionIdentifier
        }
        
        fatalError("A collection identifier has to provided!. Add a collection identifier as parameter or provide a `defaltCollectionIdentifier` for ION")
    }
}
