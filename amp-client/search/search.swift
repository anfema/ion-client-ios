//
//  fts.swift
//  amp-client
//
//  Created by Johannes Schriewer on 12/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import Markdown
import sqlite

let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)

internal extension String {
    var byteLength: Int32 {
        return Int32(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }
}

/// Full text search result item
public class AMPSearchResult {
    
    /// Page metadata object for search result
    public var meta: AMPPageMeta?
    
    /// Outlet name where the search hit
    public let outletName: String
    
    /// Text snippet of hit
    private let snippet: String
    
    internal init(collection: AMPCollection, page: String, outlet: String, snippet: String) {
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
    public func html() -> String {
        return MDParser(markdown: self.snippet).render().renderHTMLFragment()
    }
    
    /// Convert snippet to attributed string
    ///
    /// - returns: attributed string of snippet
    public func attributedString() -> NSAttributedString {
        return MDParser(markdown: self.snippet).render().renderAttributedString(AMP.config.stringStyling)
    }
}


/// Full text search handle to be re-used for subsequent fast searches
public class AMPSearchHandle {
    
    /// Collection for this handle
    public let collection: AMPCollection

    /// SQLite DB handle
    private var dbHandle: COpaquePointer = nil
    
    /// SQLite prepared statement for searching
    private var stmt: COpaquePointer = nil
    
    /// Search for a text
    ///
    /// Available modifiers: 
    /// - "phrases with spaces"
    /// - -exclusion
    ///
    /// - parameter text: text to search for
    /// - returns: list with search results, may be an empty list
    public func search(text: String) -> [AMPSearchResult] {
        let searchTerm = self.fixSearchTerm(text)
        
        sqlite3_bind_text(self.stmt, sqlite3_bind_parameter_index(self.stmt, ":locale"), AMP.config.locale, AMP.config.locale.byteLength, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, sqlite3_bind_parameter_index(stmt, ":searchTerm"), searchTerm, searchTerm.byteLength, SQLITE_TRANSIENT)

        var items = [AMPSearchResult]()
        var finished = false
        while !finished {
            let result = sqlite3_step(stmt)
            switch result {
            case SQLITE_ROW:
                guard let pageIdentifier = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 0)), encoding: NSUTF8StringEncoding),
                      let outletName     = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 1)), encoding: NSUTF8StringEncoding),
                      let snippet        = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 2)), encoding: NSUTF8StringEncoding) else {
                        continue
                }
                items.append(AMPSearchResult(collection: self.collection, page: pageIdentifier, outlet: outletName, snippet: snippet))
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

    internal init?(collection: AMPCollection) {
        self.collection = collection
        
        // Listen for fts db updates so that the sqlite connection can be reopened with the new file.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AMPSearchHandle.didUpdateFTSDB(_:)), name: AMPFTSDBDidUpdateNotification, object: nil)
        
        guard setupSqliteConnection() else
        {
            return nil
        }
    }
    
    
    @objc
    internal func didUpdateFTSDB(notification: NSNotification) {
        // Extract collection identifier from notification.
        guard let collectionIdentifier = notification.object as? String else
        {
            return
        }
        
        // Only update sqlite connection when the collection identifiers match.
        guard collectionIdentifier == collection.identifier else
        {
            return
        }
        
        setupSqliteConnection()
    }
    
    
    internal func setupSqliteConnection() -> Bool {
        guard sqlite3_open_v2(AMP.searchIndex(self.collection.identifier), &self.dbHandle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return false
        }
        
        let sql = "SELECT page, outlet, text FROM (\n\n    SELECT c.page, c.outlet, snippet(s.search, \'**\', \'**\', \'[...]\') as text, offsets(s.search) as off\n    FROM search s\n    JOIN contents c ON s.docid = c.rowid\n    WHERE\n        s.search MATCH :searchTerm AND\n        c.locale = :locale\n\n) ORDER BY length(text) ASC, (length(off) - length(replace(off, \' \', \'\')) - 1) / 2 DESC"
        guard sqlite3_prepare_v2(self.dbHandle, sql, sql.byteLength, &self.stmt, nil) == SQLITE_OK else {
            sqlite3_close(dbHandle)
            return false
        }
        
        return true
    }
    
    
    // MARK: - Private

    private func fixSearchTerm(text: String) -> String {
        if text.rangeOfString("\"") != nil {
            return text
        }
        var result = text
        result = result.stringByReplacingOccurrencesOfString(" ", withString: "* ")
        result = result.stringByReplacingOccurrencesOfString(" -", withString: " NOT ")
        return result + "*"
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        
        sqlite3_finalize(self.stmt)
        sqlite3_close(self.dbHandle)
    }
}


