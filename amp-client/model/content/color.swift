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
#if os(OSX)
    import AppKit
    #elseif os(iOS)
    import UIKit
#endif
import DEjson

/// Color content
public class AMPColorContent : AMPContent {
    /// red component (0-255)
    public var r:Int!
    
    /// green component (0-255)
    public var g:Int!

    /// blue component (0-255)
    public var b:Int!

    /// alpha component (0-255), zero is fully transparent
    public var alpha:Int!
    
    /// Initialize color content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized color content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        // make sure we're dealing with a dict
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        // make sure all data is there
        guard (dict["r"] != nil) && (dict["g"] != nil) && (dict["b"] != nil),
            case .JSONNumber(let r) = dict["r"]!,
            case .JSONNumber(let g) = dict["g"]!,
            case .JSONNumber(let b) = dict["b"]!,
            case .JSONNumber(let a) = dict["a"]! else {
                throw AMPError.InvalidJSON(json)
        }
        
        // init from deserialized data
        self.r = Int(r)
        self.g = Int(g)
        self.b = Int(b)
        self.alpha = Int(a)
    }
    
    #if os(iOS)
    /// Create an `UIColor` instance from the color object
    /// 
    /// - Returns: `UIColor` instance with values from color object
    public func color() -> UIColor? {
        return UIColor(red: CGFloat(self.r) / 255.0, green: CGFloat(self.g) / 255.0, blue: CGFloat(self.b) / 255.0, alpha: CGFloat(self.alpha) / 255.0)
    }
    #endif
    
    #if os(OSX)
    /// Create an `NSColor` instance from the color object
    ///
    /// - Returns: `NSColor` instance with values from color object
    public func color() -> NSColor? {
        return NSColor(deviceRed: CGFloat(self.r) / 255.0, green: CGFloat(self.g) / 255.0, blue: CGFloat(self.b) / 255.0, alpha: CGFloat(self.alpha) / 255.0)
    }
    #endif
}

/// Color extension to AMPPage
extension AMPPage {
    
    #if os(OSX)
    /// Fetch `NSColor` object from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `NSColor` object if the outlet was a color outlet and the page was already cached, else nil
    public func cachedColor(name: String, position: Int = 0) -> NSColor? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPColorContent = content {
                return content.color()
            }
        }
        return nil
    }
    
    /// Fetch `NSColor` object from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the color object becomes available, will not be called if the outlet
    ///                       is not a color outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func color(name: String, position: Int = 0, callback: (NSColor -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPColorContent = content {
                if let c = content.color() {
                    callback(c)
                }
            }
        }
        return self
    }
    #endif
    
    #if os(iOS)
    /// Fetch `UIColor` object from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `UIColor` object if the outlet was a color outlet and the page was already cached, else nil
    public func cachedColor(name: String, position: Int = 0) -> UIColor? {
        if let content = self.outlet(name, position: position) {
            if case let content as AMPColorContent = content {
                return content.color()
            }
        }
        return nil
    }
    
    /// Fetch `UIColor` object from named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the color object becomes available, will not be called if the outlet
    ///                       is not a color outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func color(name: String, position: Int = 0, callback: (UIColor -> Void)) -> AMPPage {
        self.outlet(name, position: position) { content in
            if case let content as AMPColorContent = content {
                if let c = content.color() {
                    callback(c)
                }
            }
        }
        return self
    }
    #endif

}