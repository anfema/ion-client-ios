//
//  collection+native_extensions.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

extension IONCollection: CustomStringConvertible {
    /// Textual description of the collection (only use for debugging purposes)
    public var description: String {
        return "IONCollection: \(identifier), \(pageMeta.count) pages"
    }
}


/// Two collections are the same if the identifier matches
///
/// - parameter lhs: IONCollection on the left hand side of `==`
/// - parameter rhs: IONCollection on the right hand side of `==`
/// - returns: `true` if the collections have the same identifiers
///            `false` if not.
///
internal func == (lhs: IONCollection, rhs: IONCollection) -> Bool {
    return (lhs.identifier == rhs.identifier)
}


extension IONCollection: Hashable {
    /// As we use the identifier for equality checks we just reuse it's hash-value for the Hashable protocol
    public var hashValue: Int {
        return identifier.hashValue
    }
}
