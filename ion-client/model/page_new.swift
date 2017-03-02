//
//  page_new.swift
//  ion_client
//
//  Created by Matthias Redlin, Dominik Felber on 28.02.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

#if os(OSX)
    import AppKit
#elseif os(iOS)
    import UIKit
#endif

/// Page class, contains functionaly to fetch outlet content
open class Page {
    
    /// Page identifier
    public var identifier: String {
        return metaData.identifier
    }
    
    /// Parent identifier, nil == top level
    public var parent: String? {
        return metaData.parent
    }
    
    /// Page layout
    public var layout: String {
        return metaData.layout
    }
    
    /// Page position (as defined in ion desk)
    public var position: Int {
        return metaData.position
    }
    
    /// Determines if the page was already full loaded
    public var isFullLoaded : Bool{
        return fullData != nil
    }
    
    /// Returns all (not full loaded) children of the Page.
    ///
    /// __Warning__: Each child page is not full loaded (can only access its meta information)
    public var metaChildren: [Page] {
        guard let _children = metaData.children else {
            return []
        }
        
        return _children.map({Page(metaData: $0)})
    }
    
    
    fileprivate (set) var metaData: IONPageMeta
    
    fileprivate (set) var fullData: IONPage?
    
    
    /// Initialize a page based on a IONPageMeta and an optional IONPage
    ///
    /// Use the `page` function from `ION`
    ///
    /// - parameter metaData: An IONPageMeta object
    /// - parameter fullData: An optional IONPage object
    init(metaData: IONPageMeta, fullData: IONPage? = nil) {
        self.metaData = metaData
        self.fullData = fullData
    }
    
    
    /// Provides a string value for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter identifier: The identifier of the outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    public func meta(_ identifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> String? {
        return metaData[identifier, position]
    }
    
    
    /// Returns an optional url of the underlying meta thumbnail.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "thumbnail" and was marked as meta information.
    public var metaThumbnailURL : URL? {
        return metaData.imageURL
    }
    
    
    /// Returns an optional url of the underlying meta icon.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "icon" and was marked as meta information.
    public var metaIconURL : URL? {
        return metaData.imageURL
    }
    
    
    #if os(iOS)
    /// Requests a thumbnail from the pages meta information.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "thumbnail" and was marked as meta information.
    public func metaThumbnail() -> AsyncResult<UIImage> {
        
        let asyncResult = AsyncResult<UIImage>()
        
        metaData.image { (result) in
    
            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            asyncResult.execute(result: .success(image))
        }
        
        return asyncResult
    }
    
    
    /// Requests an icon from the pages meta information.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "icon" and was marked as meta information.
    public func metaIcon() -> AsyncResult<UIImage> {
        return metaThumbnail()
    }
    #endif
    
    
    #if os(OSX)
    /// Requests a thumbnail from the pages meta information.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "thumbnail" and was marked as meta information.
    public func metaThumbnail() -> AsyncResult<NSImage> {
        
        let asyncResult = AsyncResult<NSImage>()
        
        metaData.image { (result) in
            
            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            asyncResult.execute(result: .success(image))
        }
        
        return asyncResult
    }
    
    
    /// Requests an icon from the pages meta information.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if an image outlet on ion desk is called "icon" and was marked as meta information.
    public func metaIcon() -> AsyncResult<NSImage> {
        return metaThumbnail()
    }
    #endif

    
    /// Returns a parent->child path of the current page
    ///
    /// - returns: A list of (not full loaded) page items (last item is current page, first item is toplevel parent)
    var path : [Page] {
        return metaData.collection?.metaPath(identifier)?.map({Page(metaData: $0)}) ?? []
    }
    
    
    deinit {
        print("Page deinitialized")
    }
}


public extension Page
{
    /// Creates an operation to fetch all (full loaded) children sorted ascending by its position.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    ///
    /// __Warning:__ The page has to be full loaded before one can access full loaded children
    ///
    /// __Note__: Each child page is fully loaded (can access all its content)
    ///
    /// __Note__: If you are only interested in the child meta information simply call `metaChildren`.
    public var children : AsyncResult<[Page]> {
        
        let asyncResult = AsyncResult<[Page]>()
        let metas       = metaChildren
        
        // Ensure that we have children that have to be loaded
        guard metas.isEmpty == false else{
            ION.config.responseQueue.async(execute: { 
                asyncResult.execute(result: .success([]))
            })
            return asyncResult
        }
        
        // Ensure that the page
        guard let fullData = fullData else{
            assertionFailure("IONPage (\(identifier)) needs to be loaded first")
            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .failure(IONError.didFail))
            })
            return asyncResult
        }
        
        var children = [Page]()
        var index    = 0
        
        fullData.children({ (result) in
            guard let child = result.value,
                  let page = metas.filter({$0.identifier == child.identifier}).first else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            
            page.fullData = child
            children.append(page)
            index += 1
            
            if index == metas.count {
                children.sort(by: {$0.position < $1.position})
                asyncResult.execute(result: .success(children))
            }
        })
        
        return asyncResult
    }
}


public extension Page {
    
    /// Provides all available contents of a Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    public var contents: [IONContent] {
        guard let fullData = fullData else {
            assertionFailure("IONPage (\(identifier)) needs to be loaded first")
            return []
        }
        
        return fullData.content
    }
    
    
    /// Provides all available contents of a specific type of a Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    public func typedContents<T: IONContent>() -> [T] {
        return (contents.filter({$0 is T})) as? [T] ?? []
    }
    
    
    /// Provides typed content of a Page based on a given outlet identifier.
    /// Furthermore take a look at the content files for easier content access.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    public func content<T: IONContent>(_ identifier: ION.OutletIdentifier,
                        at position: ION.Postion = 0) -> T? {
        
        guard let fullData = fullData else {
            assertionFailure("IONPage (\(metaData.identifier)) needs to be loaded first")
            return nil
        }
        
        let result = fullData.outlet(identifier, atPosition: position)
        
        // Validate if content is present
        guard case .success(let content) = result else {
            return nil
        }
        
        // Validate content type
        guard let typedContent = content as? T else {
            assertionFailure("Invalid content type requested (\(content.outlet))")
            return nil
        }
        
        return typedContent
    }
}
