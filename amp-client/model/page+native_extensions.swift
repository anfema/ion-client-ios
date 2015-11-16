//
//  page+native_extensions.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

extension AMPPage: CustomStringConvertible {
    public var description: String {
        return "AMPPage: \(identifier), \(content.count) content items"
    }
}

public func ==(lhs: AMPPage, rhs: AMPPage) -> Bool {
    return (lhs.collection.identifier == rhs.collection.identifier) && (lhs.identifier == rhs.identifier)
}

extension AMPPage: Hashable {
    public var hashValue: Int {
        return self.collection.hashValue + self.identifier.hashValue
    }
}
