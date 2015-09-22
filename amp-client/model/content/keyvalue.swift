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


public class AMPKeyValueContent : AMPContentBase {
    private var values:Dictionary<String, AnyObject>!
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard (dict["values"] != nil),
            case .JSONDictionary(let values) = dict["values"]! else {
                throw AMPError.Code.JSONObjectExpected(dict["values"])
        }
        
        self.values = Dictionary()
        for (key, valueObj) in values {
            switch (valueObj) {
            case .JSONString(let str):
                self.values!.updateValue(str, forKey: key)
            case .JSONNumber(let number):
                self.values!.updateValue(number, forKey: key)
            case .JSONBoolean(let boolean):
                self.values!.updateValue(boolean, forKey: key)
            default:
                throw AMPError.Code.InvalidJSON(valueObj)
            }
        }
    }
    
    subscript(index: String) -> AnyObject? {
        if let values = self.values {
            return values[index]
        }
        return nil
    }
}


extension AMPPage {
    public func valueForKey(name: String, key: String) -> AnyObject? {
        if let content = self.outlet(name) {
            if case .KeyValue(let kv) = content {
                return kv[key]
            }
        }
        return nil
    }
    
    public func valueForKey(name: String, key:String, callback: (AnyObject -> Void)) {
        self.outlet(name) { content in
            if case .KeyValue(let kv) = content {
                if let value = kv[key] {
                    callback(value)
                }
            }
        }
    }

    public func keyValue(name: String) -> Dictionary<String, AnyObject>? {
        if let content = self.outlet(name) {
            if case .KeyValue(let kv) = content {
                return kv.values
            }
        }
        return nil
    }
    
    public func keyValue(name: String, callback: (Dictionary<String, AnyObject> -> Void)) {
        self.outlet(name) { content in
            if case .KeyValue(let kv) = content {
                if let values = kv.values {
                    callback(values)
                }
            }
        }
    }
}