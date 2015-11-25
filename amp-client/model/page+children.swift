//
//  page+children.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)
import Foundation

extension AMPPage {
    
    /// fetch page children
    ///
    /// - parameter identifier: identifier of child page
    /// - parameter callback: callback to call when child page is ready, will not be called on hierarchy errors
    /// - returns: self, to be able to chain more actions to the page
    public func child(identifier: String, callback: (AMPPage -> Void)) -> AMPPage {
        self.collection.page(identifier) { page in
            if page.parent == self.identifier {
                callback(page)
            } else {
                self.callErrorHandler(.InvalidPageHierarchy(parent: self.identifier, child: page.identifier))
            }
        }
        
        return self
    }
    
    /// fetch page children
    ///
    /// - parameter identifier: identifier of child page
    /// - returns: page object that resolves async or nil if page not child of self
    public func child(identifier: String) -> AMPPage? {
        let page = self.collection.page(identifier)
        
        if page.parent == self.identifier {
            return page
        }
        self.callErrorHandler(.InvalidPageHierarchy(parent: self.identifier, child: page.identifier))
        return nil
    }
    
    
    /// enumerate page children
    ///
    /// - parameter callback: the callback to call for each child
    public func children(callback: (AMPPage -> Void)) {
        self.collection.getChildIdentifiersForPage(self.identifier) { children in
            for child in children {
                self.child(child, callback: callback)
            }
        }
    }
    
    /// list page children, Attention: those pages returned are not fully loaded!
    ///
    /// - parameter callback: the callback to call for children list
    public func childrenList(callback: ([AMPPage] -> Void)) {
        self.collection.getChildIdentifiersForPage(self.identifier) { children in
            var result = [AMPPage]()
            for child in children {
                let page = self.collection.page(child)
                result.append(page)
            }
            callback(result)
        }
    }
}