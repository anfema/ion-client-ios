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
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["r"] != nil) && (dict["g"] != nil) && (dict["b"] != nil),
            case .JSONNumber(let r) = dict["r"]!,
            case .JSONNumber(let g) = dict["g"]!,
            case .JSONNumber(let b) = dict["b"]!,
            case .JSONNumber(let a) = dict["a"]! else {
                throw AMPError.Code.InvalidJSON(json)
        }
        
        self.r = Int(r)
        self.g = Int(g)
        self.b = Int(b)
        self.alpha = Int(a)
    }
    
    public func uiColor() -> UIColor? {
        return UIColor(red: CGFloat(self.r) / 255.0, green: CGFloat(self.g) / 255.0, blue: CGFloat(self.b) / 255.0, alpha: CGFloat(self.alpha) / 255.0)
    }
}

extension AMPPage {
    public func color(name: String) -> UIColor? {
        if let content = self.outlet(name) {
            if case .Color(let color) = content {
                return color.uiColor()
            }
        }
        return nil
    }
    
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