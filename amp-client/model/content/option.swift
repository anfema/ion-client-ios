//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPOptionContent : AMPContent {
    public var value:String! /// value for the selected option
    
    /// Initialize option content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized option content object
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
    
    /// Fetch selected option for named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: string if the outlet was an option outlet and the page was already cached, else nil
    public func selectedOption(name: String) -> String? {
        if let content = self.outlet(name) {
            if case let content as AMPOptionContent = content {
                return content.value
            }
        }
        return nil
    }
    
    /// Fetch selected option for named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the option becomes available, will not be called if the outlet
    ///                       is not a option outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func selectedOption(name: String, callback: (String -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case let content as AMPOptionContent = content {
                if let value = content.value {
                    callback(value)
                }
            }
        }
        return self
    }
}