//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

// TODO: Write unittests for Number

/// Number content, has a float value
public class AMPNumberContent : AMPContent {
    /// value
    public var value:Double = 0.0
    
    /// Initialize number content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized number content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["value"] != nil),
            case .JSONNumber(let value) = dict["value"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.value = value
    }
}

/// Number extension to AMPPage
extension AMPPage {
    
    /// Return value for named number outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: value if the outlet was a number outlet and the page was already cached, else nil
    public func number(name: String) -> Double? {
        if let content = self.outlet(name) {
            if case let content as AMPNumberContent = content {
                return content.value
            }
        }
        return nil
    }
    
    /// Return value for named number outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the number becomes available, will not be called if the outlet
    ///                       is not a number outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func number(name: String, callback: (Double -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPNumberContent = content {
                callback(content.value)
            }
        }
        return self
    }
}