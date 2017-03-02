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
open class IONColorContent: IONContent {

    /// Red component (0-255)
    open var r: Int

    /// Green component (0-255)
    open var g: Int

    /// Blue component (0-255)
    open var b: Int

    /// Alpha component (0-255), zero is fully transparent
    open var alpha: Int


    /// Initialize color content object from JSON
    ///
    /// - parameter json: `JSONObject` that contains the serialized color content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.InvalidJSON` when values in `json` are missing or having the wrong type
    ///
    override init(json: JSONObject) throws {

        // Make sure we're dealing with a dict
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        // Make sure all data is there
        guard let rawR = dict["r"],
            let rawG = dict["g"],
            let rawB = dict["b"],
            let rawA = dict["a"],
            case .jsonNumber(let r) = rawR,
            case .jsonNumber(let g) = rawG,
            case .jsonNumber(let b) = rawB,
            case .jsonNumber(let a) = rawA else {
                throw IONError.invalidJSON(json)
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
    open func color() -> UIColor? {
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
    /// Fetch `NSColor` object for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an `NSColor` if the outlet is a color outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func cachedColor(_ name: String, atPosition position: Int = 0) -> Result<NSColor> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let colorContent as IONColorContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let color = colorContent.color() else {
            return .failure(IONError.outletEmpty)
        }

        return .success(color)
    }


    /// Fetch `NSColor` object for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the color outlet becomes available.
    ///                       Provides `Result.Success` containing an `NSColor` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func color(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<NSColor>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.cachedColor(name, atPosition: position))
        }
        return self
    }
    #endif


    #if os(iOS)
    /// Fetch `UIColor` object for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing a `UIColor` if the outlet is a color outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    public func cachedColor(_ name: String, atPosition position: Int = 0) -> Result<UIColor> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        guard case let colorContent as IONColorContent = content else {
            return .failure(IONError.outletIncompatible)
        }

        guard let color = colorContent.color() else {
            return .failure(IONError.outletEmpty)
        }

        return .success(color)
    }


    /// Fetch `UIColor` object for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the color outlet becomes available.
    ///                       Provides `Result.Success` containing a `UIColor` when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult public func color(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<UIColor>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.cachedColor(name, atPosition: position))
        }

        return self
    }
    #endif
}

public extension Content {
    
    /// Provides a color content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    public func colorContent(_ identifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> IONColorContent? {
        return self.content(identifier, at: position)
    }
    
    
    #if os(iOS)
    public func color(_ identifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> UIColor? {
        return colorContent(identifier)?.color()
    }
    #endif
    
    
    #if os(OSX)
    public func color(_ identifier: ION.OutletIdentifier, at position: ION.Postion = 0) -> NSColor? {
        return colorContent(identifier)?.color()
    }
    #endif
}
