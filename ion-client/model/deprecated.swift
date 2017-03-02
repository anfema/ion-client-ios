//
//  page_new_deprecated.swift
//  ion-tests
//
//  Created by Matthias Redlin on 02.03.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//

import Foundation

extension ION {
    
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
