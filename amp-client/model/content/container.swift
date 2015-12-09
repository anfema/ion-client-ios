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

/// Container content, contains other content objects
public class AMPContainerContent : AMPContent {
    /// children to this container
    public var children:[AMPContent]!
    
    /// Initialize container content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains serialized container content object
    ///
    /// Container content children can be accessed by subscripting the container content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        guard dict["children"] != nil,
            case .JSONArray(let children) = dict["children"]! else {
                throw AMPError.JSONArrayExpected(json)
        }
        
        self.children = []
        for child in children {
            do {
                try self.children!.append(AMPContent.factory(child))
            } catch {
                print("AMP: Deserialization failed")
            }
        }
    }
    
    /// Container content has a subscript for it's children
    subscript(index: Int) -> AMPContent? {
        guard self.children != nil && index < self.children!.count else {
            return nil
        }
        return self.children![index]
    }
}

/// Container extension to AMPPage
extension AMPPage {
    
    /// Fetch `AMPContent`-Array from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: Array of `AMPContent` objects if the outlet was a container outlet and the page was already
    ///            cached, else nil
    public func children(name: String, position: Int = 0) -> [AMPContent]? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPContainerContent = content {
                return content.children
            }
        }
        return nil
    }
    
    /// Fetch `AMPContent`-Array from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the children become available, will not be called if the outlet
    ///                       is not a container outlet or non-existant or fetching the outlet was canceled because
    ///                       of a communication error
    public func children(name: String, position: Int = 0, callback: ([AMPContent] -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPContainerContent = content {
                if let c = content.children {
                    callback(c)
                }
            }
        }
        return self
    }
}
