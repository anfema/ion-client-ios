//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson

/// Key/Value storage content
public class AMPKeyValueContent : AMPContent {
    /// value dictionary
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
            case .JSONArray(let values) = dict["values"]! else {
                throw AMPError.Code.JSONArrayExpected(dict["values"])
        }
        
        self.values = Dictionary()
        for item in values {
            guard case .JSONDictionary(let itemDict) = item where (itemDict["name"] != nil) && (itemDict["value"] != nil),
                  case .JSONString(let key) = itemDict["name"]!,
                  let value = itemDict["value"] else {
                    throw AMPError.Code.InvalidJSON(item)
            }
            
            switch (value) {
            case .JSONString(let str):
                self.values!.updateValue(str, forKey: key)
            case .JSONNumber(let number):
                self.values!.updateValue(number, forKey: key)
            case .JSONBoolean(let boolean):
                self.values!.updateValue(boolean, forKey: key)
            default:
                throw AMPError.Code.InvalidJSON(value)
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

/// Key/Value extension to AMPPage
extension AMPPage {
    
    /// Return value for key in named outlet
    ///
    /// - Parameter name: the name of the outlet
    /// - Parameter key: name of the value to return
    /// - Returns: value if the key exists, the outlet was a kv outlet and the page was already cached, else nil
    public func valueForKey(name: String, key: String) -> AnyObject? {
        if let content = self.outlet(name) {
            if case let content as AMPKeyValueContent = content {
                return content[key]
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
            if case let content as AMPKeyValueContent = content {
                if let value = content[key] {
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
            if case let content as AMPKeyValueContent = content {
                return content.values
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
            if case let content as AMPKeyValueContent = content {
                if let values = content.values {
                    callback(values)
                }
            }
        }
        return self
    }
}