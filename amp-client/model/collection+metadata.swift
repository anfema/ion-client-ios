//
//  collection+metadata.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

extension AMPCollection {
 
    /// Fetch page count
    ///
    /// - parameter parent: parent to get page count for, nil == top level
    /// - parameter callback: block to call for page count return value
    public func pageCount(parent: String?, callback: (Int -> Void)) -> AMPCollection {
        // append page count to work queue
        dispatch_async(self.workQueue) {
            if let result = self.pageCount(parent) {
                dispatch_async(AMP.config.responseQueue) {
                    callback(result)
                }
            }
        }
        
        return self
    }

    /// Fetch page count sync
    ///
    /// - parameter parent: parent to get page count for, nil == top level
    /// - returns: page count for parent or nil if collection is not ready
    public func pageCount(parent: String?) -> Int? {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return nil
        }
        let count = self.pageMeta.filter({ $0.parent == parent }).count
        return count
    }

    
    /// Fetch metadata
    ///
    /// - parameter identifier: page identifier to get metadata for
    /// - parameter callback: callback to call with metadata
    public func metadata(identifier: String, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        // this block fetches the page count after the collection is ready
        dispatch_async(self.workQueue) {
            if let result = self.metadata(identifier) {
                dispatch_async(AMP.config.responseQueue) {
                    callback(result)
                }
            }
        }
        
        return self
    }
    
    /// Fetch metadata sync
    ///
    /// - parameter identifier: page identifier to get metadata for
    /// - returns: AMPPageMeta object or nil if collection is not loaded
    public func metadata(identifier: String) -> AMPPageMeta? {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return nil
        }
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                return meta
            }
        }
        self.callErrorHandler(.PageNotFound(identifier))
        return nil
    }
    
    /// Enumerate metadata
    ///
    /// - parameter parent: parent to enumerate metadata for, nil == top level
    /// - parameter callback: callback to call with metadata
    public func enumerateMetadata(parent: String?, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        self.metadataList(parent) { list in
            for listItem in list {
                callback(listItem)
            }
        }
        
        return self
    }
    
    /// Fetch metadata as list
    ///
    /// - parameter parent: parent to enumerate metadata for, nil == top level
    /// - parameter callback: callback to call with metadata
    public func metadataList(parent: String?, callback: ([AMPPageMeta] -> Void)) -> AMPCollection {
        // fetch the page metadata after the collection is ready
        dispatch_async(self.workQueue) {
            dispatch_async(AMP.config.responseQueue) {
                callback(self.metadataList(parent) ?? [])
            }
        }
        
        return self
    }

    /// Fetch metadata as list sync
    ///
    /// - parameter parent: parent to enumerate metadata for, nil == top level
    /// - returns: metadata or nil if collection is not ready yet
    public func metadataList(parent: String?) -> [AMPPageMeta]? {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return nil
        }
        var result = self.pageMeta.filter({ $0.parent == parent })

        if result.count == 0 {
//            // TODO: Write test for empty metadata list
//            if let parent = parent {
//                self.callErrorHandler(.PageNotFound(parent))
//            } else {
//                self.callErrorHandler(.CollectionNotFound(self.identifier))
//            }
            return []
        } else {
            result.sortInPlace({ (page1, page2) -> Bool in
                return page1.position < page2.position
            })
            return result
        }
//        return nil
    }

    /// Fetch a parent->child path
    ///
    /// - parameter pageIdentifier: the page identifier to calculate the path for
    /// - parameter callback: callback to call with a list of metadata items (last item is requested page, first item is toplevel parent)
    /// - returns: self for chaining
    public func metaPath(pageIdentifier: String, callback: ([AMPPageMeta] -> Void)) -> AMPCollection {
        dispatch_async(self.workQueue) {
            if let result = self.metaPath(pageIdentifier) {
                dispatch_async(AMP.config.responseQueue) {
                    callback(result)
                }
            }
        }
        return self
    }

    /// Fetch a parent->child path sync
    ///
    /// - parameter pageIdentifier: the page identifier to calculate the path for
    /// - returns: a list of metadata items (last item is requested page, first item is toplevel parent) or nil if collection not ready
    public func metaPath(pageIdentifier: String) -> [AMPPageMeta]? {
        guard !self.hasFailed && self.lastUpdate != nil,
            let pagemeta = self.getPageMetaForPage(pageIdentifier) else {
                return nil
        }
        
        var result = [pagemeta]
        var parentID = pagemeta.parent
        
        while parentID != nil {
            guard let meta = self.getPageMetaForPage(parentID!) else {
                break
            }
            result.insert(meta, atIndex: 0)
            parentID = meta.parent
        }
        return result
    }

    
    /// Fetch page tree leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent:   parent from where to start the leave search (nil for toplevel)
    /// - parameter callback: callback called with unrealized page objects
    public func leaves(parent: String?, callback:([AMPPage] -> Void)) {
        dispatch_async(self.workQueue) {
            let metaItems = self.metaLeaves(parent)

            let result:[AMPPage] = metaItems.map({ meta -> AMPPage in
                return self.page(meta.identifier)
            })
            
            dispatch_async(AMP.config.responseQueue) {
                callback(result)
            }
        }
    }
    
    
    /// Fetch page tree metadata leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent:   parent from where to start the leave search (nil for toplevel)
    /// - returns:            array of `AMPPageMeta` objects
    public func metaLeaves(parent: String?) -> [AMPPageMeta] {
        
        let toplevel = self.pageMeta.filter { $0.parent == parent }
        let result = self.leaveRecursive(toplevel)
        
        return result
    }
    

    // MARK: - Internal
    
    internal func getChildIdentifiersForPage(parent: String, callback:([String] -> Void)) {
        dispatch_async(self.workQueue) {
            var temp:[AMPPageMeta] = self.pageMeta.filter({ $0.parent == parent })
            
            temp.sortInPlace({ (page1, page2) -> Bool in
                return page1.position < page2.position
            })
            
            let result: [String] = temp.flatMap({ $0.identifier })
            
            dispatch_async(AMP.config.responseQueue) {
                callback(result)
            }
        }
    }
    
    internal func getPageMetaForPage(identifier: String) -> AMPPageMeta? {
        var result: AMPPageMeta? = nil
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                result = meta
                break
            }
        }
        return result
    }

    // MARK: - Private
    private func leaveRecursive(pages: [AMPPageMeta]) -> [AMPPageMeta] {
        var result = [AMPPageMeta]()
        var check = [AMPPageMeta]()
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