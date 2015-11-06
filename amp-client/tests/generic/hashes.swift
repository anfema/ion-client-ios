//
//  hashes.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)


import XCTest
@testable import ampclient

class hashTests: DefaultXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMD2() {
        XCTAssert("".cryptoHash(.MD2) == "8350e5a3e24c153df2275c9f80692773")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.MD2) == "03d85a0d629d2c442e987525319fc471")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.MD2).hexString() == "8350e5a3e24c153df2275c9f80692773")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.MD2).hexString() == "03d85a0d629d2c442e987525319fc471")
    }

    func testMD4() {
        XCTAssert("".cryptoHash(.MD4) == "31d6cfe0d16ae931b73c59d7e0c089c0")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.MD4) == "1bee69a46ba811185c194762abaeae90")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.MD4).hexString() == "31d6cfe0d16ae931b73c59d7e0c089c0")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.MD4).hexString() == "1bee69a46ba811185c194762abaeae90")
    }

    func testMD5() {
        XCTAssert("".cryptoHash(.MD5) == "d41d8cd98f00b204e9800998ecf8427e")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.MD5) == "9e107d9d372bb6826bd81d3542a419d6")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.MD5).hexString() == "d41d8cd98f00b204e9800998ecf8427e")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.MD5).hexString() == "9e107d9d372bb6826bd81d3542a419d6")
    }

    func testSHA1() {
        XCTAssert("".cryptoHash(.SHA1) == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.SHA1) == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.SHA1).hexString() == "da39a3ee5e6b4b0d3255bfef95601890afd80709")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.SHA1).hexString() == "2fd4e1c67a2d28fced849ee1bb76e7391b93eb12")
    }

    func testSHA224() {
        XCTAssert("".cryptoHash(.SHA224) == "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.SHA224) == "730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.SHA224).hexString() == "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.SHA224).hexString() == "730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525")
    }

    func testSHA256() {
        XCTAssert("".cryptoHash(.SHA256) == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.SHA256) == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.SHA256).hexString() == "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.SHA256).hexString() == "d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592")
    }

    func testSHA384() {
        XCTAssert("".cryptoHash(.SHA384) == "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.SHA384) == "ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.SHA384).hexString() == "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.SHA384).hexString() == "ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1")
    }

    func testSHA512() {
        XCTAssert("".cryptoHash(.SHA512) == "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")
        XCTAssert("The quick brown fox jumps over the lazy dog".cryptoHash(.SHA512) == "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6")
        
        let emptyString = "".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(emptyString!.cryptoHash(.SHA512).hexString() == "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e")
        
        let foxString = "The quick brown fox jumps over the lazy dog".dataUsingEncoding(NSUTF8StringEncoding)
        XCTAssert(foxString!.cryptoHash(.SHA512).hexString() == "07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6")
    }

}
