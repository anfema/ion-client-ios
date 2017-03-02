//
//  page_new_deprecated.swift
//  ion-tests
//
//  Created by Matthias Redlin on 02.03.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//

import Foundation

extension ION {
    
    /// Tries to fetch the associated collection
    ///
    /// - parameter url: The URL the collection identifier should be extracted from to request the collection.
    /// - parameter callback: Result object either containing the `IONCollection` in succes case or an `IONError`
    ///                       when the collection could not be resolved.
    ///
    internal class func resolve(_ url: URL, callback: @escaping ((Result<IONCollection>) -> Void)) {
        guard let identifier = url.host else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }
        
        collection(identifier, callback: callback)
    }
    
    
    /// Tries to fetch the associated page
    ///
    /// - parameter url: The URL the page identifier should be extracted from to request the page.
    /// - parameter callback: Result object either containing the `IONPage` in succes case or an `IONError`
    ///                       when the page could not be resolved.
    ///
    internal class func resolve(_ url: URL, callback: @escaping ((Result<IONPage>) -> Void)) {
        let identifier = url.lastPathComponent
        guard identifier != "/" else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }
        
        resolve(url) { (result: Result<IONCollection>) in
            guard case .success(let collection) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }
            
            collection.page(identifier, callback: callback)
        }
    }
    
    
    /// Tries to fetch the associated outlet
    ///
    /// - parameter url: The URL the outlet name should be extracted from to request the outlet.
    /// - parameter callback: Result object either containing the `IONContent` in succes case or an `IONError`
    ///                       when the outlet could not be resolved.
    ///
    internal class func resolve(_ url: URL, callback: @escaping ((Result<IONContent>) -> Void)) {
        guard let name = url.fragment else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }
        
        resolve(url) { (result: Result<IONPage>) in
            guard case .success(let page) = result else {
                responseQueueCallback(callback, parameter: .failure(result.error ?? IONError.unknownError))
                return
            }
            
            page.outlet(name, callback: callback)
        }
    }
    
    /// Creates an operation to request a parent->child path for a given page identifier within a specific collection (optional).
    /// Requests a list of (not full loaded) page items (last item is current page, first item is toplevel parent).
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    /// - parameter pageIdentifier: The identifier of the page the path should be requested for
    /// - parameter collectionIdentifier: The identifier of the collection the page is contained in (optional)
    ///
    /// __Warning__: The list of pages within the path are not full loaded
//    static private func path(for pageIdentifier: PageIdentifier,
//                            in collectionIdentifier : CollectionIdentifier) -> AsyncResult<[Page]> {
//        
//        let asyncResult = AsyncResult<[Page]>()
//        
//        let validCollection = validatedCollectionIdentifier(collectionIdentifier)
//        ION.collection(validCollection) { result in
//            guard case .success(let collection) = result else {
//                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
//                return
//            }
//            
//            guard let path = collection.metaPath(pageIdentifier) else {
//                asyncResult.execute(result: .failure(IONError.pageNotFound(collection: validCollection, page: pageIdentifier)))
//                return
//            }
//            
//            
//            asyncResult.execute(result: .success(path.map({Page(metaData: $0)})))
//        }
//        
//        return asyncResult
//    }
}

extension Page {
    
    /// Provides all available contents of a specific type of a Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    public func typedContents<T: IONContent>() -> [T] {
        return (content.all.filter({$0 is T})) as? [T] ?? []
    }
}
