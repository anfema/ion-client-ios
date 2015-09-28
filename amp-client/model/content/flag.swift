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
    var enabled:Bool!
    
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
    public func isSet(name: String) -> Bool? {
        if let content = self.outlet(name) {
            if case .Flag(let flag) = content {
                return flag.enabled
            }
        }
        return nil
    }
    
    public func isSet(name: String, callback: (Bool -> Void)) {
        self.outlet(name) { content in
            if case .Flag(let flag) = content {
                callback(flag.enabled)
            }
        }
    }
}