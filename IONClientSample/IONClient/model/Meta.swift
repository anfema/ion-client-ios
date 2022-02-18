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


    /// Returns `true` if page has no children
    public var isLeaf: Bool {
        return children.isEmpty
    }


    /// Returns all (not full loaded) leaves of the Page.
    ///
    /// __Warning__: Each leaf page is not full loaded (can only access its meta information)
    public var leaves: [Page] {
        var leaves = [Page]()

        for child in children {
            let childMeta = child.meta
            leaves.append(contentsOf: childMeta.isLeaf ? [child] : childMeta.leaves)
        }

        return leaves
    }


    /// Returns a parent->child path of the current page
    ///
    /// - returns: A list of (not full loaded) page items (last item is current page, first item is toplevel parent)
    public var path: [Page] {
        return page.metaData.collection?.metaPath(page.identifier)?.map({Page(metaData: $0)}) ?? []
    }


    /// Provides a string value for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter outletIdentifier: The identifier of the outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    public func string(_ outletIdentifier: OutletIdentifier, at position: Position = 0) -> String? {
        return page.metaData[outletIdentifier, position]
    }


    /// Provides a list of string values for a given outlet that was marked as "included into page-meta" on ion desk.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter outletIdentifier: The identifier of the outlet that was marked as "included into page-meta"
    public func strings(_ outletIdentifier: OutletIdentifier) -> [String]? {
        return page.metaData.strings(outletIdentifier)
    }


    /// Provides a url for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter outletIdentifier: The identifier of the outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    public func url(_ outletIdentifier: OutletIdentifier, at position: Position = 0) -> URL? {

        guard let urlString = page.metaData[outletIdentifier, position] else {
            return nil
        }

        return URL(string: urlString)
    }


    #if os(iOS)
    // TODO: This is currently not working. Feature request to add as many image urls as required to page meta
    /// Requests an image for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    ///
    /// - parameter outletIdentifier: The identifier of the image outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    /*
    public func image(_ outletIdentifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<UIImage> {
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
    }*/


    /// Requests the thumbnail shipped with the pages meta information.
    /// The identifier of the thumbnail in meta information on ION Desk has to be set to "thumbnail" or "icon".
    /// Accessing meta data is also possible although page was not already full loaded.
    public func thumbnail(ofSize size: CGSize) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()

        page.metaData.thumbnail(withSize: size) { (result) in
            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }
            asyncResult.execute(result: .success(UIImage(cgImage: image)))
        }

        return asyncResult
    }
    #endif


    #if os(OSX)
    // TODO: This is currently not working. Feature request to add as many image urls as required to page meta
    /// Requests an image for a given outlet that was marked as "included into page-meta" on ion desk.
    /// It also takes an optional position into account for outlets containing multiple contents.
    /// Accessing meta data is also possible although page was not already full loaded.
    /// Add an onSuccess and (if needed) an onFailure handler to the operation.
    ///
    /// - parameter outletIdentifier: The identifier of the image outlet that was marked as "included into page-meta"
    /// - parameter position: Position of the content within the related outlet
    /*
    public func image(_ outletIdentifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<NSImage> {
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
    }*/


    /// Requests the thumbnail shipped with the pages meta information.
    /// The identifier of the thumbnail in meta information on ION Desk has to be set to "thumbnail" or "icon".
    /// Accessing meta data is also possible although page was not already full loaded.
    public func thumbnail(ofSize size: CGSize) -> AsyncResult<NSImage> {
        let asyncResult = AsyncResult<NSImage>()

        page.metaData.thumbnail(withSize: size) { (result) in
            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }

            let nsImage = NSImage(cgImage: image, size: CGSize(width: CGFloat(image.width), height: CGFloat(image.height)))
            asyncResult.execute(result: .success(nsImage))
        }

        return asyncResult
    }
    #endif
}
