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

public class AMPColorContent : AMPContentBase {
    var r:Int!
    var g:Int!
    var b:Int!
    var alpha:Int!
    
    /// Initialize color content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized color content object
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        // make sure we're dealing with a dict
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        // make sure all data is there
        guard (dict["r"] != nil) && (dict["g"] != nil) && (dict["b"] != nil),
            case .JSONNumber(let r) = dict["r"]!,
            case .JSONNumber(let g) = dict["g"]!,
            case .JSONNumber(let b) = dict["b"]!,
            case .JSONNumber(let a) = dict["a"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        // init from deserialized data
        self.r = Int(r)
        self.g = Int(g)
        self.b = Int(b)
        self.alpha = Int(a)
    }
    
    /// Create an `UIColor` instance from the color object
    /// 
    /// - Returns: `UIColor` instance with values from color object
    public func uiColor() -> UIColor? {
        return UIColor(red: CGFloat(self.r) / 255.0, green: CGFloat(self.g) / 255.0, blue: CGFloat(self.b) / 255.0, alpha: CGFloat(self.alpha) / 255.0)
    }
}

extension AMPPage {
    
    /// Fetch `UIColor` object from named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: `UIColor` object if the outlet was a color outlet and the page was already cached, else nil
    public func color(name: String) -> UIColor? {
        if let content = self.outlet(name) {
            if case .Color(let color) = content {
                return color.uiColor()
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
    public func color(name: String, callback: (UIColor -> Void)) {
        self.outlet(name) { content in
            if case .Color(let color) = content {
                if let c = color.uiColor() {
                    callback(c)
                }
            }
        }
    }
}