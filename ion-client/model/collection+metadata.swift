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
    /// - returns: self for chaining
    public func pageCount(_ parent: String?, callback: @escaping ((Int) -> Void)) -> IONCollection {
        // append page count to work queue
        self.workQueue.async {
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
    public func pageCount(_ parent: String?) -> Int? {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return nil
        }

        return self.pageMeta.filter({ $0.parent == parent }).count
    }


    /// Fetch metadata
    ///
    /// - parameter identifier: Page identifier to get metadata for
    /// - parameter callback: Callback to call with metadata
    /// - returns: self for chaining
    public func metadata(_ identifier: String, callback: @escaping ((Result<IONPageMeta>) -> Void)) -> IONCollection {
        // this block fetches the page count after the collection is ready
        self.workQueue.async {
            let result = self.metadata(identifier)
            responseQueueCallback(callback, parameter: result)
        }

        return self
    }


    /// Fetch metadata sync
    ///
    /// - parameter identifier: Page identifier to get metadata for
    /// - returns: `IONPageMeta` object or nil if collection is not loaded
    public func metadata(_ identifier: String) -> Result<IONPageMeta> {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return .failure(IONError.didFail)
        }

        for meta in self.pageMeta {
            if meta.identifier == identifier {
                return .success(meta)
            }
        }

        return .failure(IONError.pageNotFound(identifier))
    }


    /// Fetch metadata as list
    ///
    /// - parameter parent: Parent to enumerate metadata for, nil == top level
    /// - parameter callback: Callback to call with metadata
    /// - returns: self for chaining
    public func metadataList(_ parent: String?, callback: @escaping ((Result<[IONPageMeta]>) -> Void)) -> IONCollection {
        // fetch the page metadata after the collection is ready
        self.workQueue.async {
            responseQueueCallback(callback, parameter: self.metadataList(parent))
        }

        return self
    }


    /// Fetch metadata as list sync
    ///
    /// - parameter parent: Parent to enumerate metadata for, nil == top level
    /// - returns: Metadata or nil if collection is not ready yet
    public func metadataList(_ parent: String?) -> Result<[IONPageMeta]> {
        guard !self.hasFailed && self.lastUpdate != nil else {
            return .failure(IONError.didFail)
        }

        var result = self.pageMeta.filter({ $0.parent == parent })
        result.sort(by: { (page1, page2) -> Bool in
            return page1.position < page2.position
        })

        return .success(result)
    }


    /// Fetch a parent->child path
    ///
    /// - parameter pageIdentifier: The page identifier to calculate the path for
    /// - parameter callback: Callback to call with a list of metadata items (last item is requested page, first item is toplevel parent)
    /// - returns: self for chaining
    public func metaPath(_ pageIdentifier: String, callback: @escaping ((Result<[IONPageMeta]>) -> Void)) -> IONCollection {
        self.workQueue.async {
            guard let result = self.metaPath(pageIdentifier) else {
                responseQueueCallback(callback, parameter: .failure(IONError.pageNotFound(pageIdentifier)))
                return
            }

            responseQueueCallback(callback, parameter: .success(result))
        }

        return self
    }


    /// Fetch a parent->child path sync
    ///
    /// - parameter pageIdentifier: The page identifier to calculate the path for
    /// - returns: A list of metadata items (last item is requested page, first item is toplevel parent) or nil if collection not ready
    public func metaPath(_ pageIdentifier: String) -> [IONPageMeta]? {
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

            result.insert(meta, at: 0)
            parentID = meta.parent
        }

        return result
    }


    /// Fetch page tree leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent: Parent from where to start the leave search (nil for toplevel)
    /// - parameter callback: Callback called with unrealized page objects
    public func leaves(_ parent: String?, callback: @escaping (([IONPage]) -> Void)) {
        self.workQueue.async {
            let metaItems = self.metaLeaves(parent)
            let result: [IONPage] = metaItems.map({ self.page($0.identifier) })

            responseQueueCallback(callback, parameter: result)
        }
    }


    /// Fetch page tree metadata leaves from parent (walks down the page tree and returns all leaves at the end)
    ///
    /// - parameter parent: Parent from where to start the leave search (nil for toplevel)
    /// - returns: Array of `IONPageMeta` objects
    public func metaLeaves(_ parent: String?) -> [IONPageMeta] {
        let toplevel = self.pageMeta.filter({ $0.parent == parent })
        let result = self.leaveRecursive(toplevel)

        return result
    }


    // MARK: - Internal

    internal func getChildIdentifiersForPage(_ parent: String, callback: @escaping (([String]) -> Void)) {
        self.workQueue.async {
            var temp: [IONPageMeta] = self.pageMeta.filter({ $0.parent == parent })

            temp.sort(by: { (page1, page2) -> Bool in
                return page1.position < page2.position
            })

            let result: [String] = temp.flatMap({ $0.identifier })

            responseQueueCallback(callback, parameter: result)
        }
    }


    internal func getPageMetaForPage(_ identifier: String) -> IONPageMeta? {
        for meta in self.pageMeta {
            if meta.identifier == identifier {
                return meta
            }
        }

        return nil
    }


    // MARK: - Private
    fileprivate func leaveRecursive(_ pages: [IONPageMeta]) -> [IONPageMeta] {
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

        if check.isEmpty == false {
            result.append(contentsOf: self.leaveRecursive(check))
        }

        return result
    }
}
