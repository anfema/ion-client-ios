//
//  fts.swift
//  ion-client
//
//  Created by Johannes Schriewer on 12/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Markdown
import SQLite


/// Full text search result item
open class IONSearchResult {

    /// Page metadata object for search result
    open var page: Page?

    /// Outlet name where the search hit
    public let outletName: String

    /// Text snippet of hit
    fileprivate let snippet: String


    internal init(collection: IONCollection, page: String, outlet: String, snippet: String) {
        self.outletName = outlet
        self.snippet = snippet

        if let meta = collection.pageMeta.first(where: {$0.identifier == page}) {
            self.page = Page(metaData: meta)
        }
    }

    /// Convert snippet to HTML
    ///
    /// - returns: html fragment of snippet
    open func html() -> String {
        return MDParser(markdown: self.snippet).render().renderHTMLFragment()
    }

    /// Convert snippet to attributed string
    ///
    /// - returns: attributed string of snippet
    open func attributedString() -> NSAttributedString {
        return MDParser(markdown: self.snippet).render().renderAttributedString(usingStyle: ION.config.stringStyling)
    }
}


/// Full text search handle to be re-used for subsequent fast searches
open class IONSearchHandle {

    /// Collection for this handle
    internal let collection: IONCollection

    /// Connection to the SQLite Database
    fileprivate var connection: Connection?

    /// Query statement for search
    private let sql = "SELECT page, outlet, text FROM (\n\n    SELECT c.page, c.outlet, snippet(s.search, \'**\', \'**\', \'[...]\') as text, offsets(s.search) as off\n    FROM search s\n    JOIN contents c ON s.docid = c.rowid\n    WHERE\n        s.search MATCH :searchTerm AND\n        c.locale = :locale\n\n) ORDER BY length(text) ASC, (length(off) - length(replace(off, \' \', \'\')) - 1) / 2 DESC"

    /// Search for a text
    ///
    /// Available modifiers:
    /// - "phrases with spaces"
    /// - -exclusion
    ///
    /// - parameter text: text to search for
    /// - returns: list with search results, may be an empty list
    open func search(for text: String) -> [IONSearchResult] {
        guard let connection = self.connection else {
            return []
        }

        let searchTerm = text.fixedSearchTerm

        guard let statement = try? connection.prepare(sql, [":locale": ION.config.locale, ":searchTerm": searchTerm]) else {
            return []
        }

        var items = [IONSearchResult]()

        for item in statement {
            guard let pageIdentifier = item[0] as? String else { continue }
            guard let outletName = item[1] as? String else { continue }
            guard let snippet = item[2] as? String else { continue }

            items.append(IONSearchResult(collection: self.collection, page: pageIdentifier, outlet: outletName, snippet: snippet))
        }

        return items
    }

    // MARK: - Internal

    internal init?(collection: IONCollection) {
        self.collection = collection

        // Listen for fts db updates so that the sqlite connection can be reopened with the new file.
        NotificationCenter.default.addObserver(self, selector: #selector(IONSearchHandle.didUpdateFTSDB(notification:)), name: Notification.ftsDatabaseDidUpdate, object: nil)

        guard setupSqliteConnection() else {
            return nil
        }
    }


    @objc
    internal func didUpdateFTSDB(notification: Foundation.Notification) {
        // Extract collection identifier from notification.
        guard let collectionIdentifier = notification.object as? String else {
            return
        }

        // Only update sqlite connection when the collection identifiers match.
        guard collectionIdentifier == collection.identifier else {
            return
        }

        _ = setupSqliteConnection()
    }


    internal func setupSqliteConnection() -> Bool {
        guard let searchIndex = ION.searchIndex(forCollection: self.collection.identifier) else {
            return false
        }

        guard let db = try? Connection(searchIndex, readonly: true) else {
            return false
        }

        self.connection = db

        return true
    }


    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


fileprivate extension String {
    var fixedSearchTerm: String {
        if range(of: "\"") != nil {
            return self
        }

        var result = self
        result = result.replacingOccurrences(of: " ", with: "* ")
        result = result.replacingOccurrences(of: " -", with: " NOT ")
        return result + "*"
    }
}
