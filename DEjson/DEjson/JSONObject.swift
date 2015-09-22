//
//  JSONObject.swift
//  DeJSON
//
//  Created by Johannes Schriewer on 04.02.15.
//  Copyright (c) 2015 anfema. All rights reserved.
//

import Foundation

public enum JSONObject {
    case JSONArray(Array<JSONObject>)
    case JSONDictionary(Dictionary<String, JSONObject>)
    case JSONString(String)
    case JSONNumber(Double)
    case JSONBoolean(Bool)
    case JSONNull
    case JSONInvalid
    
    public init(_ string: String) {
        self = .JSONInvalid
    }
}
