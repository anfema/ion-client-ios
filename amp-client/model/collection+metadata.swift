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
    /// - Parameter parent: parent to get page count for, nil == top level
    /// - Parameter callback: block to call for page count return value
    public func pageCount(parent: String?, callback: (Int -> Void)) -> AMPCollection {
        // append page count to work queue
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var count = 0
            for meta in self.pageMeta {
                if meta.parent == parent {
                    count++
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(count)
            }
        }
        
        return self
    }
    
    /// Fetch metadata
    ///
    /// - Parameter identifier: page identifier to get metadata for
    /// - Parameter callback: callback to call with metadata
    public func metadata(identifier: String, callback: (AMPPageMeta -> Void)) -> AMPCollection {
        // this block fetches the page count after the collection is ready
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var found = false
            for meta in self.pageMeta {
                if meta.identifier == identifier {
                    dispatch_async(AMP.config.responseQueue) {
                        callback(meta)
                    }
                    found = true
                    break
                }
            }
            if !found {
                self.callErrorHandler(.PageNotFound(identifier))
            }
        }
        
        return self
    }
    
    /// Enumerate metadata
    ///
    /// - Parameter parent: parent to enumerate metadata for, nil == top level
    /// - Parameter callback: callback to call with metadata
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
    /// - Parameter parent: parent to enumerate metadata for, nil == top level
    /// - Parameter callback: callback to call with metadata
    public func metadataList(parent: String?, callback: ([AMPPageMeta] -> Void)) -> AMPCollection {
        // fetch the page metadata after the collection is ready
        dispatch_async(self.workQueue) {
            guard !self.hasFailed else {
                return
            }
            var result = [AMPPageMeta]()
            for meta in self.pageMeta {
                if meta.parent == parent {
                    result.append(meta)
                }
            }
            if result.count == 0 {
                if let parent = parent {
                    self.callErrorHandler(.PageNotFound(parent))
                } else {
                    self.callErrorHandler(.CollectionNotFound(self.identifier))
                }
            } else {
                result.sortInPlace({ (page1, page2) -> Bool in
                    return page1.position < page2.position
                })
                dispatch_async(AMP.config.responseQueue) {
                    callback(result)
                }
            }
        }
        
        return self
    }
    
    // MARK: - Internal
    
    internal func getChildIdentifiersForPage(parent: String, callback:([String] -> Void)) {
        dispatch_async(self.workQueue) {
            var result:[String] = []
            
            var temp:[AMPPageMeta] = []
            for meta in self.pageMeta {
                if meta.parent == parent {
                    temp.append(meta)
                }
            }
            temp.sortInPlace({ (page1, page2) -> Bool in
                return page1.position < page2.position
            })
            for item in temp {
                result.append(item.identifier)
            }
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

}