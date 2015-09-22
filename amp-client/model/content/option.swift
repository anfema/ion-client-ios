//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import UIKit
import DEjson


public class AMPOptionContent : AMPContentBase {
    var value:String!
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["value"] != nil),
            case .JSONString(let value) = dict["value"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.value = value
    }
}

extension AMPPage {
    public func selectedOption(name: String) -> String? {
        if let content = self.outlet(name) {
            if case .Option(let opt) = content {
                return opt.value
            }
        }
        return nil
    }
    
    public func selectedOption(name: String, callback: (String -> Void)) {
        self.outlet(name) { content in
            if case .Option(let opt) = content {
                if let value = opt.value {
                    callback(value)
                }
            }
        }
    }
}