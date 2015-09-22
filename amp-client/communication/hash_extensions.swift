//
//  HashExtensions.swift
//  CustomMade
//
//  Created by Dominik Felber on 26.08.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation
import CommonCrypto

extension Int {
    func hexString() -> String {
        return NSString(format: "%02x", self) as String
    }
}

extension NSData {
    typealias hashFunctionType = (UnsafePointer<Void>, CC_LONG, UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>
    
    func hexString() -> String {
        var string = String()
        let bytes = UnsafePointer<UInt8>(self.bytes)
        
        for i in UnsafeBufferPointer<UInt8>(start: bytes, count: self.length) {
            string += Int(i).hexString()
        }
        
        return string
    }
    
    func applyHashAlgorithm(hashAlgorithm: hashFunctionType, digestLength: Int) -> NSData {
        let result = NSMutableData(length: digestLength)!
        hashAlgorithm(self.bytes, CC_LONG(self.length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        
        return NSData(data: result)
    }
    
    // MARK: MD5
    func md5() -> NSData {
        return applyHashAlgorithm(CC_MD5, digestLength: Int(CC_MD5_DIGEST_LENGTH))
    }
    
    
    class func md5(data: NSData) -> NSData {
        return data.md5()
    }
    
    
    // MARK: SHA1
    func sha1() -> NSData {
        return applyHashAlgorithm(CC_SHA1, digestLength: Int(CC_SHA1_DIGEST_LENGTH))
    }
    
    
    class func sha1(data: NSData) -> NSData {
        return data.sha1()
    }
    
    
    // MARK: SHA224
    func sha224() -> NSData {
        return applyHashAlgorithm(CC_SHA224, digestLength: Int(CC_SHA224_DIGEST_LENGTH))
    }
    
    
    class func sha224(data: NSData) -> NSData {
        return data.sha224()
    }
    
    
    // MARK: SHA256
    func sha256() -> NSData {
        return applyHashAlgorithm(CC_SHA256, digestLength: Int(CC_SHA256_DIGEST_LENGTH))
    }
    
    
    class func sha256(data: NSData) -> NSData {
        return data.sha256()
    }
    
    
    // MARK: SHA384
    func sha384() -> NSData {
        return applyHashAlgorithm(CC_SHA384, digestLength: Int(CC_SHA384_DIGEST_LENGTH))
    }
    
    
    class func sha384(data: NSData) -> NSData {
        return data.sha384()
    }
    
    
    // MARK: SHA512
    func sha512() -> NSData {
        return applyHashAlgorithm(CC_SHA512, digestLength: Int(CC_SHA512_DIGEST_LENGTH))
    }
    
    
    class func sha512(data: NSData) -> NSData {
        return data.sha512()
    }
}


extension String {
    func hashedString(hashFunction: (NSData -> NSData)) -> String {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else { return "" }
        let hashedData = hashFunction(data)
        
        return hashedData.hexString()
    }
    

    func md5() -> String {
        return hashedString(NSData.md5)
    }
    
    
    func sha1() -> String {
        return hashedString(NSData.sha1)
    }
    
    
    func sha224() -> String {
        return hashedString(NSData.sha224)
    }
    
    
    func sha256() -> String {
       return hashedString(NSData.sha256)
    }
    
    
    func sha384() -> String {
        return hashedString(NSData.sha384)
    }
    
    
    func sha512() -> String {
        return hashedString(NSData.sha512)
    }
}