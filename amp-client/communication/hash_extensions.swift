//
//  HashExtensions.swift
//  CustomMade
//
//  Created by Dominik Felber on 26.08.15.
//  Refactored by Johannes Schriewer on 24.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation
import CommonCrypto

public enum HashTypes : String {
    typealias HashFunction = (UnsafePointer<Void>, CC_LONG, UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>

    case MD2 = "md2"
    case MD4 = "md4"
    case MD5 = "md5"
    case SHA1 = "sha1"
    case SHA224 = "sha224"
    case SHA256 = "sha256"
    case SHA384 = "sha384"
    case SHA512 = "sha512"
    
    var digestLength: Int {
        get {
            switch self {
            case .MD2:
                return Int(CC_MD2_DIGEST_LENGTH)
            case .MD4:
                return Int(CC_MD4_DIGEST_LENGTH)
            case .MD5:
                return Int(CC_MD5_DIGEST_LENGTH)
            case .SHA1:
                return Int(CC_SHA1_DIGEST_LENGTH)
            case .SHA224:
                return Int(CC_SHA224_DIGEST_LENGTH)
            case .SHA256:
                return Int(CC_SHA256_DIGEST_LENGTH)
            case .SHA384:
                return Int(CC_SHA384_DIGEST_LENGTH)
            case .SHA512:
                return Int(CC_SHA512_DIGEST_LENGTH)
            }
        }
    }
    
    var hashFunction: HashFunction {
        get {
            switch self {
            case .MD2:
                return CC_MD2
            case .MD4:
                return CC_MD4
            case .MD5:
                return CC_MD5
            case .SHA1:
                return CC_SHA1
            case .SHA224:
                return CC_SHA224
            case .SHA256:
                return CC_SHA256
            case .SHA384:
                return CC_SHA384
            case .SHA512:
                return CC_SHA512
            }
        }
    }
}

extension UInt8 {
    /// Convert value into 2 byte hex-string
    ///
    /// - Returns: 2 byte hex string of value
    func hexString() -> String {
        return NSString(format: "%02x", self) as String
    }
}

extension NSData {
    
    /// Convert bytes into hex-string
    ///
    /// - Returns: hex string of `self.bytes`
    public func hexString() -> String {
        var string = String()
        let bytes = UnsafePointer<UInt8>(self.bytes)
        
        for i in UnsafeBufferPointer<UInt8>(start: bytes, count: self.length) {
            string += i.hexString()
        }
        
        return string
    }
    
    /// Calculate cryptographic hash
    ///
    /// - Parameter type: the hash method to use
    /// - Returns: `NSData` with binary hash value
    public func cryptoHash(type: HashTypes) -> NSData {
        let result = NSMutableData(length: type.digestLength)!
        type.hashFunction(self.bytes, CC_LONG(self.length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        
        return NSData(data: result)
    }
    
    /// Calculate cryptographic hash
    ///
    /// - Parameter data: data to hash
    /// - Parameter type: the hash method to use
    /// - Returns: `NSData` with binary hash value
    public class func cryptoHash(data: NSData, type: HashTypes) -> NSData {
        return data.cryptoHash(type)
    }
}


extension String {
    
    /// Calculate cryptographic hash
    ///
    /// - Parameter type: the hash method to use
    /// - Returns: String with hex-encoded hash value
    public func cryptoHash(type: HashTypes) -> String {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else { return "" }
        let hashedData = data.cryptoHash(type)
        return hashedData.hexString()
    }
}