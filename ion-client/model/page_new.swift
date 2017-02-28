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

/// Page class, contains functionaly to fetch outlet content
open class Page {
    
    private (set) var metaData: IONPageMeta
    
    private (set) var fullData: IONPage?
    
    
    /// Initialize a page based on a IONPageMeta and an optional IONPage
    ///
    /// Use the `page` function from `ION`
    ///
    /// - parameter metaData: An IONPageMeta object
    /// - parameter fullData: An optional IONPage object
    init(metaData: IONPageMeta, fullData: IONPage?) {
        self.metaData = metaData
        self.fullData = fullData
    }
    
    
    /// Provides a string that was marked as the pages metainformation respecting a given position.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// - parameter identifier: The identifier of the content that was marked as meta information
    /// - parameter position: Position within the meta information value if the value is an array of strings
    public func meta(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> String? {
        return metaData[identifier, position]
    }
    
    
    /// Returns an optional url of the underlying meta thumbnail.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if a content on ION-Desk is called "thumbnail" and was marked as meta information.
    public var metaThumbnailURL : URL? {
        return metaData.imageURL
    }
    
    
    /// Returns an optional url of the underlying meta icon.
    /// Accessing meta data is also possible although page was not already full loaded.
    ///
    /// __Note__: Works if a content on ION-Desk is called "icon" and was marked as meta information.
    public var metaIconURL : URL? {
        return metaData.imageURL
    }
    
    
    deinit {
        print("Page deinitialized")
    }
}


public extension Page {
    
    /// Provides all available contents of a Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access an content (except meta data)
    public var contents: [IONContent] {
        guard let fullData = fullData else {
            assertionFailure("IONPage (\(metaData.identifier)) needs to be loaded first")
            return []
        }
        
        return fullData.content
    }
    
    
    /// Provides all available contents of a specific type of a Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access an content (except meta data)
    public func typedContents<T: IONContent>() -> [T] {
        return (contents.filter({$0 is T})) as? [T] ?? []
    }
    
    
    /// Provides a content of a specific type of a Page.
    /// Furthermore take a look at the content files for easier content access.
    ///
    /// __Warning:__ The page has to be full loaded before one can access an content (except meta data)
    public func content<T: IONContent>(_ identifier: ION.ContentIdentifier, at position: ION.Postion = 0) -> T? {
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
