//
//  page+children.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)
import Foundation


extension IONPage {

    /// Fetch page children
    ///
    /// - parameter identifier: Identifier of child page
    /// - parameter callback: Block to call when the child page becomes ready.
    ///                       Provides Result.Success containing an `IONPage` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    /// - returns: self, to be able to chain more actions to the page
    public func child(identifier: String, callback: (Result<IONPage, IONError> -> Void)) -> IONPage {
        self.collection.page(identifier) { result in
            guard case .Success(let page) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .DidFail))
                return
            }

            guard page.parent == self.identifier else {
                responseQueueCallback(callback, parameter: .Failure(.InvalidPageHierarchy(parent: self.identifier, child: page.identifier)))
                return
            }

            responseQueueCallback(callback, parameter: .Success(page))
        }

        return self
    }


    /// Fetch page children
    ///
    /// - parameter identifier: Identifier of child page
    /// - returns: Page object that resolves asynchronously or nil if the page is no child of self
    public func child(identifier: String) -> Result<IONPage, IONError> {
        let page = self.collection.page(identifier)

        guard page.metadata != nil else {
            return .Failure(.PageNotFound(identifier))
        }

        guard page.parent == self.identifier else {
            return .Failure(.InvalidPageHierarchy(parent: self.identifier, child: page.identifier))
        }

        return .Success(page)
    }


    /// Enumerate page children
    ///
    /// - parameter callback: The callback to call for each child
    public func children(callback: (Result<IONPage, IONError> -> Void)) {
        self.collection.getChildIdentifiersForPage(self.identifier) { children in
            for child in children {
                self.child(child, callback: callback)
            }
        }
    }


    /// List page children, Attention: those pages returned are not fully loaded!
    ///
    /// - parameter callback: The callback to call for children list
    public func childrenList(callback: ([IONPage] -> Void)) {
        self.collection.getChildIdentifiersForPage(self.identifier) { children in
            var result = [IONPage]()

            for child in children {
                let page = self.collection.page(child)
                result.append(page)
            }

            responseQueueCallback(callback, parameter: result)
        }
    }
}
