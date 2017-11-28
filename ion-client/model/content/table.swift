//
//  table.swift
//  ion-client
//
//  Created by Matthias Redlin on 24.11.17.
//  Copyright © 2017 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson


/// Table content containing a string array per row
open class IONTableContent: IONContent {

    /// Underlying table containing a string array per row
    open var table: [[String?]]


    /// Initialize table content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized table content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {

        guard case .jsonDictionary(let dict) = json else {

            throw IONError.jsonObjectExpected(json)
        }

        guard let rawTableRows = dict["rows"],
            case .jsonArray(let tableRowsArray) = rawTableRows else {

                throw IONError.invalidJSON(json)
        }

        var tableRows = [[String?]]()

        for rawRow in tableRowsArray {

            guard case .jsonArray(let rowArray) = rawRow else {
                throw IONError.invalidJSON(json)
            }

            var rowValues = [String?]()

            for rawValue in rowArray {

                if case .jsonString(let value) = rawValue {
                    rowValues.append(value)
                    continue
                } else if case .jsonNull = rawValue {
                    rowValues.append(nil)
                    continue
                }

                throw IONError.invalidJSON(json)
            }

            tableRows.append(rowValues)
        }

        self.table = tableRows

        try super.init(json: json)
    }


    /// Returns number of rows in table.
    ///
    /// - returns: Number of rows in table
    var rows: Int {

        return table.count
    }


    /// Returns number of columns for a specific row.
    ///
    /// - parameter row: Row to return columns for
    /// - returns: Number of columns or 0
    func columns(forRow row: Int) -> Int {

        guard row < table.count else { return 0 }

        return table[row].count
    }


    /// Returns underlying text for specified row and column.
    ///
    /// - parameter row: Row to return text for
    /// - parameter column: Column to return text for
    /// - returns: Text or nil
    func text(forRow row: Int, column: Int) -> String? {

        guard row < table.count else { return nil }

        let row = table[row]

        guard column < row.count else { return nil }

        return row[column]
    }

    /// IONTable can be subscripted by row and column to fetch text
    ///
    /// - parameter row: Row to return text for
    /// - parameter column: Column to return text for
    /// - returns: Text or nil
    open subscript(row: Int, column: Int) -> String? {
        return text(forRow: row, column: column)
    }
}


public extension Content {

    /// Provides a table content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    public func tableContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONTableContent? {
        return self.content(identifier, at: position)
    }


    public func tableContents(_ identifier: OutletIdentifier) -> [IONTableContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONTableContent] ?? nil)
    }


    public func table(_ identifier: OutletIdentifier, at position: Position = 0) -> [[String?]]? {
        guard let content = tableContent(identifier) else {
            return nil
        }

        return content.table
    }
}
