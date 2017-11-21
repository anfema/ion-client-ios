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

    internal private (set) var metaData: IONPageMeta

    internal private (set) var fullData: IONPage?

    public var meta: Meta {
        return Meta(page: self)
    }

    public var content: Content {
        return Content(page: self)
    }

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
    public var isFullyLoaded: Bool {
        return fullData != nil
    }


    /// Initialize a page based on a IONPageMeta and an optional IONPage
    ///
    /// Use the `page` function from `ION`
    ///
    /// - parameter metaData: An IONPageMeta object
    /// - parameter fullData: An optional IONPage object
    internal init(metaData: IONPageMeta, fullData: IONPage? = nil) {
        self.metaData = metaData
        self.fullData = fullData
    }


    /// Creates an operation to fetch all (full loaded) children sorted ascending by its position.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    ///
    /// __Note__: Each child page is fully loaded (can access all its content)
    ///
    /// __Note__: If you are only interested in the child meta information simply call `.meta.children`.
    public var children: AsyncResult<[Page]> {

        let asyncResult = AsyncResult<[Page]>()
        let metas       = meta.children

        // Ensure that we have children that have to be loaded
        guard metas.isEmpty == false else {
            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .success([]))
            })
            return asyncResult
        }

        var children = [Page]()

        metas.forEach { (meta) in
            ION.page(pageIdentifier: meta.identifier, in: meta.metaData.collectionIdentifier, option: .full).onSuccess({ (page) in
                children.append(page)

                if children.count == metas.count {
                    children.sort(by: {$0.position < $1.position})
                    asyncResult.execute(result: .success(children))
                }
            }).onFailure({ (error) in
                asyncResult.execute(result: .failure(error))
            })
        }

        return asyncResult
    }


    /// Loads the current page fully.
    /// Add an `onSuccess` and (if needed) an `onFailure` handler to the operation.
    /// The result on success references self while self is now fully loaded.
    ///
    public func load() -> AsyncResult<Page> {

        let asyncResult = AsyncResult<Page>()

        guard isFullyLoaded == false else {

            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .success(self))
            })

            return asyncResult
        }

        ION.page(pageIdentifier: identifier, in: metaData.collectionIdentifier, option: .full).onSuccess({ [weak self] (fullPage) in

            guard let strongSelf = self else {
                return
            }

            strongSelf.fullData = fullPage.fullData

            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .success(strongSelf))
            })

        }).onFailure({ (error) in

            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .failure(error))
            })
        })

        return asyncResult
    }


    deinit {
    }
}

extension Page: Equatable {
    public static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.identifier == rhs.identifier && lhs.metaData.collectionIdentifier == rhs.metaData.collectionIdentifier
    }
}

extension Page: Hashable {
    public var hashValue: Int {
        return identifier.hashValue ^ metaData.collectionIdentifier.hashValue
    }
}


extension Page: CustomDebugStringConvertible {
    public var debugDescription: String {
        let parentInfo = self.parent ?? "none"
        let collectionInfo = self.metaData.collectionIdentifier
        let outletsInfo = self.isFullyLoaded ? "\(self.content.all.count)" : "unknown"

        return "Page (\(self.identifier))\n" +
            " • parent: \(parentInfo)\n" +
            " • collection: \(collectionInfo)\n" +
            " • data: \(self.isFullyLoaded ? "full" : "meta")\n" +
            " • outlets: \(outletsInfo)\n" +
            " • children: \(self.meta.children.count)\n"
    }
}
