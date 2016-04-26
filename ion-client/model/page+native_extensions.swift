//
//  page+native_extensions.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation


extension IONPage: CustomStringConvertible {
    /// Convert page to string representation, only use for debugging purposes
    public var description: String {
        return "IONPage: \(identifier), \(content.count) content items"
    }
}


/// Two pages are the same if the identifier and the collection matches
public func ==(lhs: IONPage, rhs: IONPage) -> Bool {
    return (lhs.collection.identifier == rhs.collection.identifier) && (lhs.identifier == rhs.identifier)
}


extension IONPage: Hashable {
    /// Combine collection hash value with self identifier hash value to get somewhat unique hash
    public var hashValue: Int {
        return self.collection.hashValue + self.identifier.hashValue
    }
}