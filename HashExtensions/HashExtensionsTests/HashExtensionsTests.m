//
//  HashExtensionsTests.m
//  HashExtensionsTests
//
//  Created by Johannes Schriewer on 10/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

#import <XCTest/XCTest.h>
@import HashExtensions;

#define empty @""
#define fox @"The quick brown fox jumps over the lazy dog"

#define emptyData [empty dataUsingEncoding:NSUTF8StringEncoding]
#define foxData [fox dataUsingEncoding:NSUTF8StringEncoding]

@interface HashExtensionsTests : XCTestCase

@end

@implementation HashExtensionsTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMD2 {
    HashType t = hashTypeFromName(@"MD2");
    XCTAssertEqual(t, HashTypeMD2);
    XCTAssert([[empty cryptoHash: t] isEqualToString:@"8350e5a3e24c153df2275c9f80692773"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"03d85a0d629d2c442e987525319fc471"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"8350e5a3e24c153df2275c9f80692773"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"03d85a0d629d2c442e987525319fc471"]);
}

- (void)testMD4 {
    HashType t = hashTypeFromName(@"MD4");
    XCTAssertEqual(t, HashTypeMD4);
    
    XCTAssert([[empty cryptoHash: t] isEqualToString:@"31d6cfe0d16ae931b73c59d7e0c089c0"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"1bee69a46ba811185c194762abaeae90"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"31d6cfe0d16ae931b73c59d7e0c089c0"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"1bee69a46ba811185c194762abaeae90"]);
}

- (void)testMD5 {
    HashType t = hashTypeFromName(@"MD5");
    XCTAssertEqual(t, HashTypeMD5);
    
    XCTAssert([[empty cryptoHash: t] isEqualToString:@"d41d8cd98f00b204e9800998ecf8427e"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"9e107d9d372bb6826bd81d3542a419d6"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"d41d8cd98f00b204e9800998ecf8427e"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"9e107d9d372bb6826bd81d3542a419d6"]);
}

- (void)testSHA1 {
    HashType t = hashTypeFromName(@"SHA1");
    XCTAssertEqual(t, HashTypeSHA1);
    
    XCTAssert([[empty cryptoHash: t] isEqualToString:@"da39a3ee5e6b4b0d3255bfef95601890afd80709"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"da39a3ee5e6b4b0d3255bfef95601890afd80709"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"2fd4e1c67a2d28fced849ee1bb76e7391b93eb12"]);
}

- (void)testSHA224 {
    HashType t = hashTypeFromName(@"SHA224");
    XCTAssertEqual(t, HashTypeSHA224);
    
    XCTAssert([[empty cryptoHash: t] isEqualToString:@"d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"730e109bd7a8a32b1cb9d9a09aa2325d2430587ddbc0c38bad911525"]);
}

- (void)testSHA256 {
    HashType t = hashTypeFromName(@"SHA256");
    XCTAssertEqual(t, HashTypeSHA256);

    XCTAssert([[empty cryptoHash: t] isEqualToString:@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"d7a8fbb307d7809469ca9abcb0082e4f8d5651e46d3cdb762d02d0bf37c9e592"]);
}

- (void)testSHA384 {
    HashType t = hashTypeFromName(@"SHA384");
    XCTAssertEqual(t, HashTypeSHA384);

    XCTAssert([[empty cryptoHash: t] isEqualToString:@"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"ca737f1014a48f4c0b6dd43cb177b0afd9e5169367544c494011e3317dbf9a509cb1e5dc1e85a941bbee3d7f2afbc9b1"]);
}

- (void)testSHA512 {
    HashType t = hashTypeFromName(@"SHA512");
    XCTAssertEqual(t, HashTypeSHA512);

    XCTAssert([[empty cryptoHash: t] isEqualToString:@"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"]);
    XCTAssert([[fox cryptoHash: t] isEqualToString:@"07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6"]);
    
    XCTAssert([[emptyData cryptoHash: t].hexString isEqualToString:@"cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e"]);
    XCTAssert([[foxData cryptoHash: t].hexString isEqualToString:@"07e547d9586f6a73f73fbac0435ed76951218fb7d0c8d788a309d785436bbb642e93a252a954f23912547d1e8a3b5ed6e1bfd7097821233fa0538f3db854fee6"]);
}


@end
