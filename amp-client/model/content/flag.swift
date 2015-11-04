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

/// Flag content, can be enabled or not
public class AMPFlagContent : AMPContent {
    /// status of the flag
    public var enabled:Bool!
    
    /// Initialize flag content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized flag content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["is_enabled"] != nil),
            case .JSONBoolean(let enabled) = dict["is_enabled"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.enabled = enabled
    }
}

/// Flag extension to AMPPage
extension AMPPage {

    /// Check if flag is set for named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: true or false if the outlet was a flag outlet and the page was already cached, else nil
    public func isSet(name: String) -> Bool? {
        if let content = self.outlet(name) {
            if case let content as AMPFlagContent = content {
                return content.enabled
            }
        }
        return nil
    }
    
    /// Check if flag is set for named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the flag becomes available, will not be called if the outlet
    ///                       is not a flag outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func isSet(name: String, callback: (Bool -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPFlagContent = content {
                callback(content.enabled)
            }
        }
        return self
    }
}