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

/// Connection content, carries a link to another collection/page/outlet
public class AMPConnectionContent : AMPContent {
    
    /// value for the selected option
    public var link:String!
    
    /// url convenience
    public var url: NSURL? {
        return NSURL(string: "amp://\(self.link)")
    }
    
    /// Initialize option content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized option content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard (dict["connection_string"] != nil),
            case .JSONString(let value) = dict["connection_string"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        self.link = value
    }
}

/// Option extensions to AMPPage
extension AMPPage {
    
    /// Fetch selected option for named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: string if the outlet was an option outlet and the page was already cached, else nil
    public func link(name: String, position: Int = 0) -> NSURL? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPConnectionContent = content {
                return content.url
            }
        }
        return nil
    }
    
    /// Fetch selected option for named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the option becomes available, will not be called if the outlet
    ///                       is not a option outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func link(name: String, position: Int = 0, callback: (NSURL -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPConnectionContent = content {
                if let url = content.url {
                    callback(url)
                }
            }
        }
        return self
    }
}