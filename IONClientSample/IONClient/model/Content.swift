//
//  Content.swift
//  ion-tests
//
//  Created by Matthias Redlin on 02.03.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//

import Foundation

public struct Content {

    private let page: Page

    init(page: Page) {
        self.page = page
    }

    /// Provides all available contents of a single Page.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    public var all: [IONContent] {
        guard let fullData = page.fullData else {
            assertionFailure("IONPage (\(page.identifier)) needs to be loaded first")
            return []
        }

        return fullData.content
    }


    /// Provides typed content of a Page based on a given outlet identifier.
    /// Furthermore take a look at the content files for easier content access.
    ///
    /// __Warning:__ The page has to be full loaded before one can access content (except meta data)
    func content<T: IONContent>(_ identifier: OutletIdentifier, at position: Position = 0) -> T? {
        guard let fullData = page.fullData else {
            assertionFailure("IONPage (\(page.identifier)) needs to be loaded first")
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
