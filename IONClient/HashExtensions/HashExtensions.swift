//
//  HashExtensions.swift
//  IONClient
//
//  Created by Matthias Redlin on 18.02.22.
//  Copyright © 2022 anfema. All rights reserved.
//

import Foundation
import CryptoKit

extension Insecure.MD5Digest
{
    var hexString: String
    {
        return makeIterator()
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

extension SHA256Digest
{
    var hexString: String
    {
        return makeIterator()
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
