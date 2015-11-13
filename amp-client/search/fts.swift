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

let SQLITE_STATIC = unsafeBitCast(0, sqlite3_destructor_type.self)
let SQLITE_TRANSIENT = unsafeBitCast(-1, sqlite3_destructor_type.self)

public class AMPSearchResult {
    public var meta: AMPPageMeta?
    public let outletName: String
    private let snippet: String
    
    internal init(collection: String, page: String, outlet: String, snippet: String) {
        self.outletName = outlet
        self.snippet = snippet
        AMP.collection(collection).metadata(page) { meta in
            self.meta = meta
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

public extension AMPCollection {
    private func searchIndex() -> String {
        return "/Users/johannes/Desktop/fts_db.sqlite3"
    }
    
    public func search(text: String, callback: ([AMPSearchResult] -> Void)) {
        dispatch_async(self.workQueue) {
            var dbHandle: COpaquePointer = nil
            var stmt: COpaquePointer = nil
            
            guard sqlite3_open_v2(self.searchIndex(), &dbHandle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
                return
            }
            defer {
                sqlite3_close(dbHandle)
            }
            
            let sql = "SELECT page, outlet, text FROM (\n\n    SELECT c.page, c.outlet, snippet(s.search, \'**\', \'**\', \'[...]\') as text, offsets(s.search) as off\n    FROM search s\n    JOIN contents c ON s.docid = c.rowid\n    WHERE\n        s.search MATCH :searchTerm AND\n        c.collection = :collection AND\n        c.locale = :locale\n\n) ORDER BY length(text) ASC, (length(off) - length(replace(off, \' \', \'\')) - 1) / 2 DESC"
            guard sqlite3_prepare_v2(dbHandle, sql, sql.byteLength, &stmt, nil) == SQLITE_OK else {
                return
            }
            defer {
                sqlite3_finalize(stmt)
            }
            
            // TODO: modify search text to fit sqlite syntax
            sqlite3_bind_text(stmt, sqlite3_bind_parameter_index(stmt, ":collection"), self.identifier, self.identifier.byteLength, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, sqlite3_bind_parameter_index(stmt, ":locale"), AMP.config.locale, AMP.config.locale.byteLength, SQLITE_TRANSIENT)
            sqlite3_bind_text(stmt, sqlite3_bind_parameter_index(stmt, ":searchTerm"), text, text.byteLength, SQLITE_TRANSIENT)
            
            var items = [AMPSearchResult]()
            var finished = false
            while !finished {
                let result = sqlite3_step(stmt)
                switch result {
                case SQLITE_ROW:
                    guard let pageIdentifier = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 0)), encoding: NSUTF8StringEncoding),
                          let outletName     = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 1)), encoding: NSUTF8StringEncoding),
                          let snippet = String(CString: UnsafePointer<CChar>(sqlite3_column_text(stmt, 2)), encoding: NSUTF8StringEncoding) else {
                            continue
                    }
                    items.append(AMPSearchResult(collection: self.identifier, page: pageIdentifier, outlet: outletName, snippet: snippet))
                case SQLITE_DONE:
                    finished = true
                default:
                    finished = true
                }
            }
            dispatch_async(AMP.config.responseQueue) {
                callback(items)
            }
        }
    }
}