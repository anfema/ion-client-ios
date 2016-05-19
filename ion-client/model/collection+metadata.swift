//
//  collection+metadata.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation


extension IONCollection {
 
    /// Fetch page count
    ///
    /// - parameter parent: Parent to get page count for, nil == top level
    /// - parameter callback: Block to call for page count return value
    public func pageCount(parent: String?, callback: (Int -> Void)) -> IONCollection {
        // append page count to work queue
        dispatch_async(self.workQueue) {
            if let result = self.pageCount(parent) {
                responseQueueCallback(callback, parameter: result)
            }
        }
        
        return self
    }
    

    /// Fetch page count sync
    ///
    /// - parameter parent: Parent to get page count for, nil == top level
    /// - returns: Page count for parent or nil if collection is not ready
    public func pageCount(parent: String?) -> Int? {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return nil
        }
        
        return self.pageMeta.filter({ $0.parent == parent }).count
    }

    
    /// Fetch metadata
    ///
    /// - parameter identifier: Page identifier to get metadata for
    /// - parameter callback: Callback to call with metadata
    public func metadata(identifier: String, callback: (Result<IONPageMeta, IONError> -> Void)) -> IONCollection {
        // this block fetches the page count after the collection is ready
        dispatch_async(self.workQueue) {
            let result = self.metadata(identifier)
            responseQueueCallback(callback, parameter: result)
        }
        
        return self
    }
    
    
    /// Fetch metadata sync
    ///
    /// - parameter identifier: Page identifier to get metadata for
    /// - returns: `IONPageMeta` object or nil if collection is not loaded
    public func metadata(identifier: String) -> Result<IONPageMeta, IONError> {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return .Failure(.DidFail)
        }
        
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                return .Success(meta)
            }
        }
        
        return .Failure(.PageNotFound(identifier))
    }
    
    
    /// Fetch metadata as list
    ///
    /// - parameter parent: Parent to enumerate metadata for, nil == top level
    /// - parameter callback: Callback to call with metadata
    public func metadataList(parent: String?, callback: (Result<[IONPageMeta], IONError> -> Void)) -> IONCollection {
        // fetch the page metadata after the collection is ready
        dispatch_async(self.workQueue) {
            responseQueueCallback(callback, parameter: self.metadataList(parent))
        }
        
        return self
    }

    
    /// Fetch metadata as list sync
    ///
    /// - parameter parent: Parent to enumerate metadata for, nil == top level
    /// - returns: Metadata or nil if collection is not ready yet
    public func metadataList(parent: String?) -> Result<[IONPageMeta], IONError> {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return .Failure(.DidFail)
        }
        
        var result = self.pageMeta.filter({ $0.parent == parent })
        result.sortInPlace({ (page1, page2) -> Bool in
            return page1.position < page2.position
        })
        
        return .Success(result)
    }
    

    /// Fetch a parent->child path
    ///
    /// - parameter pageIdentifier: The page identifier to calculate the path for
    /// - parameter callback: Callback to call with a list of metadata items (last item is requested page, first item is toplevel parent)
    /// - returns: self for chaining
    public func metaPath(pageIdentifier: String, callback: (Result<[IONPageMeta], IONError> -> Void)) -> IONCollection {
        dispatch_async(self.workQueue) {
            guard let result = self.metaPath(pageIdentifier) else {
                responseQueueCallback(callback, parameter: .Failure(IONError.PageNotFound(pageIdentifier)))
                return
            }
            
            responseQueueCallback(callback, parameter: .Success(result))
        }
        
        return self
    }

    
    /// Fetch a parent->child path sync
    ///
    /// - parameter pageIdentifier: The page identifier to calculate the path for
    /// - returns: A list of metadata items (last item is requested page, first item is toplevel parent) or nil if collection not ready
    public func metaPath(pageIdentifier: String) -> [IONPageMeta]? {
        guard !self.hasFailed && self.lastUpdate != nil,
            let pagemeta = self.getPageMetaForPage(pageIdentifier) else {
                return nil
        }
        
        var result = [pagemeta]
        var parentID = pagemeta.parent
        
        while parentID != nil {
            guard let p = parentID,
                  let meta = self.getPageMetaForPage(p) else {
                break
            }
            
            result.insert(meta, atIndex: 0)
            parentID = meta.parent
        }
        
        return result
    }

    
    /// Fetch page tree leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent: Parent from where to start the leave search (nil for toplevel)
    /// - parameter callback: Callback called with unrealized page objects
    public func leaves(parent: String?, callback: ([IONPage] -> Void)) {
        dispatch_async(self.workQueue) {
            let metaItems = self.metaLeaves(parent)
            let result: [IONPage] = metaItems.map({ self.page($0.identifier) })
            
            responseQueueCallback(callback, parameter: result)
        }
    }
    
    
    /// Fetch page tree metadata leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent: Parent from where to start the leave search (nil for toplevel)
    /// - returns: Array of `IONPageMeta` objects
    public func metaLeaves(parent: String?) -> [IONPageMeta] {
        let toplevel = self.pageMeta.filter({ $0.parent == parent })
        let result = self.leaveRecursive(toplevel)
        
        return result
    }
    

    // MARK: - Internal
    
    internal func getChildIdentifiersForPage(parent: String, callback: ([String] -> Void)) {
        dispatch_async(self.workQueue) {
            var temp: [IONPageMeta] = self.pageMeta.filter({ $0.parent == parent })
            
            temp.sortInPlace({ (page1, page2) -> Bool in
                return page1.position < page2.position
            })
            
            let result: [String] = temp.flatMap({ $0.identifier })
            
            responseQueueCallback(callback, parameter: result)
        }
    }
    
    
    internal func getPageMetaForPage(identifier: String) -> IONPageMeta? {
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                return meta
            }
        }
        
        return nil
    }

    
    // MARK: - Private
    private func leaveRecursive(pages: [IONPageMeta]) -> [IONPageMeta] {
        var result = [IONPageMeta]()
        var check = [IONPageMeta]()
        
        for page in pages {
            var is_leaf = true
            
            for meta in self.pageMeta {
                if meta.parent == page.identifier {
                    is_leaf = false
                    check.append(meta)
                }
            }
            
            if is_leaf {
                result.append(page)
            }
        }
        
        if check.count > 0 {
            result.appendContentsOf(self.leaveRecursive(check))
        }
        
        return result
    }
}