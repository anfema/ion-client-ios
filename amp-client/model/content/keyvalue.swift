//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson


public class AMPKeyValueContent : AMPContentBase {
    private var values:Dictionary<String, AnyObject>!
    
    /// Initialize key value content object from JSON
    ///
    /// - Parameter json: `JSONObject` that contains serialized key value content object
    ///
    /// Values can be accessed by subscripting the object with a string
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
    
    /// subscripting with a key yields the value
    subscript(index: String) -> AnyObject? {
        if let values = self.values {
            return values[index]
        }
        return nil
    }
}


extension AMPPage {
    
    /// Return value for key in named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter key: name of the value to return
    /// - Returns: value if the key exists, the outlet was a kv outlet and the page was already cached, else nil
    public func valueForKey(name: String, key: String) -> AnyObject? {
        if let content = self.outlet(name) {
            if case .KeyValue(let kv) = content {
                return kv[key]
            }
        }
        return nil
    }
    
    /// Fetch value for key in named outlet async
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter key: name of the value to return
    /// - Parameter callback: block to call when the value becomes available, will not be called if the outlet
    ///                       is not a kv outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func valueForKey(name: String, key:String, callback: (AnyObject -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case .KeyValue(let kv) = content {
                if let value = kv[key] {
                    callback(value)
                }
            }
        }
        return self
    }

    /// Return a key/value dictionary for named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Returns: dict if the outlet was a kv outlet and the page was already cached, else nil
    public func keyValue(name: String) -> Dictionary<String, AnyObject>? {
        if let content = self.outlet(name) {
            if case .KeyValue(let kv) = content {
                return kv.values
            }
        }
        return nil
    }
    
    /// Fetch key/value dictionary for named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter callback: block to call when the dict becomes available, will not be called if the outlet
    ///                       is not a kv outlet or non-existant or fetching the outlet was canceled because of a
    ///                       communication error
    public func keyValue(name: String, callback: (Dictionary<String, AnyObject> -> Void)) -> AMPPage {
        self.outlet(name) { content in
            if case .KeyValue(let kv) = content {
                if let values = kv.values {
                    callback(values)
                }
            }
        }
        return self
    }
}