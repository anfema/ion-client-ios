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

public class AMPContainerContent : AMPContentBase {
    var children:Array<AMPContent>!
    
    override init(json:JSONObject) throws {
        try super.init(json: json)
        
        guard case .JSONDictionary(let dict) = json else {
            throw AMPError.Code.JSONObjectExpected(json)
        }
        
        guard dict["children"] != nil,
            case .JSONArray(let children) = dict["children"]! else {
                throw AMPError.Code.JSONArrayExpected(json)
        }
        
        self.children = []
        for child in children {
            try self.children!.append(AMPContent(json: child))
        }
    }
    
    subscript(index: Int) -> AMPContent? {
        guard self.children != nil && index < self.children!.count else {
            return nil
        }
        return self.children![index]
    }
}

extension AMPPage {
    public func children(name: String) -> Array<AMPContent>? {
        if let content = self.outlet(name) {
            if case .Container(let container) = content {
                return container.children
            }
        }
        return nil
    }
    
    public func children(name: String, callback: (Array<AMPContent> -> Void)) {
        self.outlet(name) { content in
            if case .Container(let container) = content {
                if let c = container.children {
                    callback(c)
                }
            }
        }
    }
}
