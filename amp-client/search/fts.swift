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

public class AMPSearchResult {
    public var meta: AMPPageMeta?
    public let outletName: String
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
    
    public func html() -> String {
        return MDParser(markdown: self.snippet).render().renderHTMLFragment()
    }
    
    public func attributedString() -> NSAttributedString {
        return MDParser(markdown: self.snippet).render().renderAttributedString(AMP.config.stringStyling)
    }
}

extension String {
    var byteLength: Int32 {
        return Int32(self.lengthOfBytesUsingEncoding(NSUTF8StringEncoding))
    }
}

public class AMPSearchHandle {
    private var dbHandle: COpaquePointer = nil
    private var stmt: COpaquePointer = nil
    public let collection: AMPCollection
    
    private func searchIndex() -> String {
        return "/Users/johannes/Code/amp/amp/project_template/media/fts_db.sqlite3"
    }

    private func fixSearchTerm(text: String) -> String {
        if text.rangeOfString("\"") != nil {
            return text
        }
        var result = text
        result = result.stringByReplacingOccurrencesOfString(" ", withString: "* ")
        result = result.stringByReplacingOccurrencesOfString(" -", withString: " NOT ")
        return result
    }
    
    internal init?(collection: AMPCollection) {
        self.collection = collection

        guard sqlite3_open_v2(self.searchIndex(), &self.dbHandle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return nil
        }
        
        let sql = "SELECT page, outlet, text FROM (\n\n    SELECT c.page, c.outlet, snippet(s.search, \'**\', \'**\', \'[...]\') as text, offsets(s.search) as off\n    FROM search s\n    JOIN contents c ON s.docid = c.rowid\n    WHERE\n        s.search MATCH :searchTerm AND\n        c.collection = :collection AND\n        c.locale = :locale\n\n) ORDER BY length(text) ASC, (length(off) - length(replace(off, \' \', \'\')) - 1) / 2 DESC"
        guard sqlite3_prepare_v2(self.dbHandle, sql, sql.byteLength, &self.stmt, nil) == SQLITE_OK else {
            sqlite3_close(dbHandle)
            return nil
        }
        
    }
    
    public func search(text: String) -> [AMPSearchResult] {
        let searchTerm = self.fixSearchTerm(text)
        
        sqlite3_bind_text(self.stmt, sqlite3_bind_parameter_index(self.stmt, ":collection"), self.collection.identifier, self.collection.identifier.byteLength, SQLITE_TRANSIENT)
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
    
    deinit {
        sqlite3_finalize(self.stmt)
        sqlite3_close(self.dbHandle)
    }
}

public extension AMPCollection {
    public func getSearchHandle(callback: (AMPSearchHandle -> Void)) {
        dispatch_async(self.workQueue) {
            if let handle = AMPSearchHandle(collection: self) {
                callback(handle)
            }
        }
    }
}