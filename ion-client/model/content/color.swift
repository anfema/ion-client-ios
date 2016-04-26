//
//  content.swift
//  ion-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
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
public class IONColorContent: IONContent {
    
    /// Red component (0-255)
    public var r: Int
    
    /// Green component (0-255)
    public var g: Int

    /// Blue component (0-255)
    public var b: Int

    /// Alpha component (0-255), zero is fully transparent
    public var alpha: Int
    
    
    /// Initialize color content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized color content object
    override init(json: JSONObject) throws {
        
        // Make sure we're dealing with a dict
        guard case .JSONDictionary(let dict) = json else {
            throw IONError.JSONObjectExpected(json)
        }
        
        // Make sure all data is there
        guard let rawR = dict["r"],
            let rawG = dict["g"],
            let rawB = dict["b"],
            let rawA = dict["a"],
            case .JSONNumber(let r) = rawR,
            case .JSONNumber(let g) = rawG,
            case .JSONNumber(let b) = rawB,
            case .JSONNumber(let a) = rawA else {
                throw IONError.InvalidJSON(json)
        }
        
        // Init from deserialized data
        self.r = Int(r)
        self.g = Int(g)
        self.b = Int(b)
        self.alpha = Int(a)

        try super.init(json: json)
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


/// Color extension to IONPage
extension IONPage {
    
    #if os(OSX)
    /// Fetch `NSColor` object from named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: Result.Success containing an `NSColor` if the outlet is a color outlet
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
    public func cachedColor(name: String, position: Int = 0) -> Result<NSColor, IONError> {
        let result = self.outlet(name, position: position)
    
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
        
        if case let content as IONColorContent = content {
            if let color = content.color() {
                return .Success(color)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
        
        return .Failure(.OutletIncompatible)
    }
    
    
    /// Fetch `NSColor` object from named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the color outlet becomes available.
    ///                       Provides Result.Success containing an `NSColor` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    public func color(name: String, position: Int = 0, callback: (Result<NSColor, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.cachedColor(name, position: position))
        }
    
        return self
    }
    #endif
    
    
    #if os(iOS)
    /// Fetch `UIColor` object from named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: Result.Success containing a `UIColor` if the outlet is a color outlet
    ///            and the page was already cached, else an Result.Failure containing an `IONError`.
    public func cachedColor(name: String, position: Int = 0) -> Result<UIColor, IONError> {
        let result = self.outlet(name, position: position)
        
        guard case .Success(let content) = result else {
            return .Failure(result.error ?? .UnknownError)
        }
    
        if case let content as IONColorContent = content {
            if let color = content.color() {
                return .Success(color)
            } else {
                return .Failure(.OutletEmpty)
            }
        }
    
        return .Failure(.OutletIncompatible)
    }
    
    
    /// Fetch `UIColor` object from named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the color outlet becomes available.
    ///                       Provides Result.Success containing a `UIColor` when successful, or
    ///                       Result.Failure containing an `IONError` when an error occurred.
    public func color(name: String, position: Int = 0, callback: (Result<UIColor, IONError> -> Void)) -> IONPage {
        dispatch_async(workQueue) {
            responseQueueCallback(callback, parameter: self.cachedColor(name, position: position))
        }
        
        return self
    }
    #endif
}