//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPFlagContent : AMPContentBase {
    var enabled:Bool! /// status of the flag
    
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

extension AMPPage {

    /// Check if flag is set for named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: true or false if the outlet was a flag outlet and the page was already cached, else nil
    public func isSet(name: String) -> Bool? {
        if let content = self.outlet(name) {
            if case .Flag(let flag) = content {
                return flag.enabled
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
            if case .Flag(let flag) = content {
                callback(flag.enabled)
            }
        }
        return self
    }
}