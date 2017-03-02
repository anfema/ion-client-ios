//
//  Meta.swift
//  ion-tests
//
//  Created by Matthias Redlin on 02.03.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//

import Foundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif


public struct Meta {
    
    private let page: Page
    
    init(page: Page) {
        self.page = page
    }
    
    
    /// Returns all (not full loaded) children of the Page.
    ///
    /// __Warning__: Each child page is not full loaded (can only access its meta information)
    public var children: [Page] {
        guard let _children = page.metaData.children else {
            return []
        }
        
        return _children.map({Page(metaData: $0)})
    }
    
    
    /// Returns a parent->child path of the current page
    ///
    /// - returns: A list of (not full loaded) page items (last item is current page, first item is toplevel parent)
    public var path : [Page] {
        return page.metaData.collection?.metaPath(page.identifier)?.map({Page(metaData: $0)}) ?? []
    }
    
    
    /// Provides a string value for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter outletIdentifier: The identifier of the outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    public func string(_ outletIdentifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> String? {
        return page.metaData[outletIdentifier, position]
    }
    
    
    /// Provides a url for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter outletIdentifier: The identifier of the outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    public func url(_ outletIdentifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> URL? {
        
        guard let urlString = page.metaData[outletIdentifier, position] else {
            return nil
        }
        
        return URL(string: urlString)
    }
    
    
    #if os(iOS)
    public func image(_ outletIdentifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()
        
        guard let imageURLString = string(outletIdentifier, at: position),
            let imageURL = URL(string: imageURLString)  else {
                
            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .failure(IONError.didFail))
            })
        
            return asyncResult
        }
        
        let imageContent = IONImageContent(url: imageURL, outletIdentifier: outletIdentifier)
        
        imageContent.image { (result) in
            asyncResult.execute(result: result)
        }
        
        return asyncResult
    }
    #endif
    
    
    #if os(OSX)
    public func image(_ outletIdentifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> AsyncResult<NSImage> {
        let asyncResult = AsyncResult<NSImage>()
        
        guard let imageURLString = string(outletIdentifier, at: position),
            let imageURL = URL(string: imageURLString)  else {
                
                ION.config.responseQueue.async(execute: {
                    asyncResult.execute(result: .failure(IONError.didFail))
                })
                
                return asyncResult
        }
        
        let imageContent = IONImageContent(url: imageURL, outletIdentifier: outletIdentifier)
        
        imageContent.image { (result) in
            asyncResult.execute(result: result)
        }
        
        return asyncResult
    }
    #endif
}
