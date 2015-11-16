//
//  collection+native_extensions.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

extension AMPCollection: CustomStringConvertible {
    public var description: String {
        return "AMPCollection: \(identifier!), \(pageMeta.count) pages"
    }
}

public func ==(lhs: AMPCollection, rhs: AMPCollection) -> Bool {
    return (lhs.identifier == rhs.identifier)
}

extension AMPCollection: Hashable {
    public var hashValue: Int {
        return identifier.hashValue
    }
}
