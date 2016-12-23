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

#if os(OSX)
    import sqlite_MacOSX
#elseif os(iOS)
#if (arch(i386) || arch(x86_64))
    import sqlite_iPhoneSimulator
    #else
    import sqlite_iPhoneOS
#endif
#endif

let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

internal extension String {
    var byteLength: Int32 {
        return Int32(self.lengthOfBytes(using: String.Encoding.utf8))
    }
}

/// Full text search result item
open class IONSearchResult {

    /// Page metadata object for search result
    open var meta: IONPageMeta?

    /// Outlet name where the search hit
    open let outletName: String

    /// Text snippet of hit
    fileprivate let snippet: String

    internal init(collection: IONCollection, page: String, outlet: String, snippet: String) {
        self.outletName = outlet
        self.snippet = snippet
        for meta in collection.pageMeta {
            if meta.identifier == page {
                self.meta = meta
            }
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
    open let collection: IONCollection

    /// SQLite DB handle
    fileprivate var dbHandle: OpaquePointer? = nil

    /// SQLite prepared statement for searching
    fileprivate var stmt: OpaquePointer? = nil

    /// Search for a text
    ///
    /// Available modifiers:
    /// - "phrases with spaces"
    /// - -exclusion
    ///
    /// - parameter text: text to search for
    /// - returns: list with search results, may be an empty list
    open func search(for text: String) -> [IONSearchResult] {
        let searchTerm = text.fixedSearchTerm

        sqlite3_bind_text(self.stmt, sqlite3_bind_parameter_index(self.stmt, ":locale"), ION.config.locale, ION.config.locale.byteLength, sqliteTransient)
        sqlite3_bind_text(stmt, sqlite3_bind_parameter_index(stmt, ":searchTerm"), searchTerm, searchTerm.byteLength, sqliteTransient)

        var items = [IONSearchResult]()
        var finished = false
        while !finished {
            let result = sqlite3_step(stmt)
            switch result {
            case SQLITE_ROW:
                // TODO: Check if this is safe??
                let pageIdentifier = String(cString: sqlite3_column_text(stmt, 0))
                let outletName     = String(cString: sqlite3_column_text(stmt, 1))
                let snippet        = String(cString: sqlite3_column_text(stmt, 2))
                items.append(IONSearchResult(collection: self.collection, page: pageIdentifier, outlet: outletName, snippet: snippet))
            case SQLITE_DONE:
                finished = true
            default:
                finished = true
            }
        }
        sqlite3_reset(self.stmt)
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
        guard let searchIndex = ION.searchIndex(forCollection: self.collection.identifier), sqlite3_open_v2(searchIndex, &self.dbHandle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return false
        }

        let sql = "SELECT page, outlet, text FROM (\n\n    SELECT c.page, c.outlet, snippet(s.search, \'**\', \'**\', \'[...]\') as text, offsets(s.search) as off\n    FROM search s\n    JOIN contents c ON s.docid = c.rowid\n    WHERE\n        s.search MATCH :searchTerm AND\n        c.locale = :locale\n\n) ORDER BY length(text) ASC, (length(off) - length(replace(off, \' \', \'\')) - 1) / 2 DESC"
        guard sqlite3_prepare_v2(self.dbHandle, sql, sql.byteLength, &self.stmt, nil) == SQLITE_OK else {
            sqlite3_close(dbHandle)
            return false
        }

        return true
    }
    

    deinit {
        NotificationCenter.default.removeObserver(self)

        sqlite3_finalize(self.stmt)
        sqlite3_close(self.dbHandle)
    }
}


fileprivate extension String
{
    fileprivate var fixedSearchTerm : String
    {
        if range(of: "\"") != nil {
            return self
        }
        
        var result = self
        result = result.replacingOccurrences(of: " ", with: "* ")
        result = result.replacingOccurrences(of: " -", with: " NOT ")
        return result + "*"
    }
}
