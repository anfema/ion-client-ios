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
import Alamofire

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
    /// - parameter json: `JSONObject` that contains serialized color content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        // make sure we're dealing with a dict
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.JSONObjectExpected(json)
        }
        
        // make sure all data is there
        guard let rawR = dict["r"], rawG = dict["g"], rawB = dict["b"], rawA = dict["a"],
            case .JSONNumber(let r) = rawR,
            case .JSONNumber(let g) = rawG,
            case .JSONNumber(let b) = rawB,
            case .JSONNumber(let a) = rawA else {
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
    /// - returns: `UIColor` instance with values from color object
    public func color() -> UIColor? {
        return UIColor(red: CGFloat(self.r) / 255.0, green: CGFloat(self.g) / 255.0, blue: CGFloat(self.b) / 255.0, alpha: CGFloat(self.alpha) / 255.0)
    }
    #endif
    
    #if os(OSX)
    /// Create an `NSColor` instance from the color object
    ///
    /// - returns: `NSColor` instance with values from color object
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
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `NSColor` object if the outlet was a color outlet and the page was already cached, else nil
    public func cachedColor(name: String, position: Int = 0) -> Result<NSColor, AMPError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
        
        if case let content as AMPColorContent = content {
            if let color = content.color() {
                return .Success(color)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch `NSColor` object from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the color object becomes available, will not be called if the outlet
    ///                       is not a color outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func color(name: String, position: Int = 0, callback: (Result<NSColor, AMPError> -> Void)) -> AMPPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                callback(.Failure(result.error!))
                return
            }
            
            if case let content as AMPColorContent = content {
                if let c = content.color() {
                    callback(.Success(c))
                } else {
                    callback(.Failure(.OutletEmpty))
                }
            } else {
                callback(.Failure(.OutletIncompatible))
            }
        }
        return self
    }
    #endif
    
    #if os(iOS)
    /// Fetch `UIColor` object from named outlet
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - returns: `UIColor` object if the outlet was a color outlet and the page was already cached, else nil
    public func cachedColor(name: String, position: Int = 0) -> Result<UIColor, AMPError> {
        let result = self.outlet(name, position: position)
        guard case .Success(let content) = result else {
            return .Failure(result.error!)
        }
    
        if case let content as AMPColorContent = content {
            if let color = content.color() {
                return .Success(color)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
    
        return .Failure(.OutletIncompatible)
    }
    
    /// Fetch `UIColor` object from named outlet async
    ///
    /// - parameter name: the name of the outlet
    /// - parameter position: (optional) position in the array
    /// - parameter callback: block to call when the color object becomes available, will not be called if the outlet
    ///                       is not a color outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func color(name: String, position: Int = 0, callback: (Result<UIColor, AMPError> -> Void)) -> AMPPage {
        self.outlet(name, position: position) { result in
            guard case .Success(let content) = result else {
                callback(.Failure(result.error!))
                return
            }
            
            if case let content as AMPColorContent = content {
                if let c = content.color() {
                    callback(.Success(c))
                } else {
                    callback(.Failure(.OutletEmpty))
                }
            } else {
                callback(.Failure(.OutletIncompatible))
            }
        }
        return self
    }
    #endif

}