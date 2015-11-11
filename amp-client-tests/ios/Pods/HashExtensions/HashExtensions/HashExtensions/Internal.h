//
//  Internal.h
//  HashExtensions
//
//  Created by Johannes Schriewer on 10/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

#import <CommonCrypto/CommonCrypto.h>

static inline size_t digestLength(HashType hash) {
    switch (hash) {
        case HashTypeMD2:
            return CC_MD2_DIGEST_LENGTH;
        case HashTypeMD4:
            return CC_MD4_DIGEST_LENGTH;
        case HashTypeMD5:
            return CC_MD5_DIGEST_LENGTH;
        case HashTypeSHA1:
            return CC_SHA1_DIGEST_LENGTH;
        case HashTypeSHA224:
            return CC_SHA224_DIGEST_LENGTH;
        case HashTypeSHA256:
            return CC_SHA256_DIGEST_LENGTH;
        case HashTypeSHA384:
            return CC_SHA384_DIGEST_LENGTH;
        case HashTypeSHA512:
            return CC_SHA512_DIGEST_LENGTH;
        default:
            return 0;
    }
}

typedef unsigned char *(*hashFunctionType)(const void *data, CC_LONG len, unsigned char *md);

static inline hashFunctionType hashFunction(HashType hash) {
    switch (hash) {
        case HashTypeMD2:
            return CC_MD2;
        case HashTypeMD4:
            return CC_MD4;
        case HashTypeMD5:
            return CC_MD5;
        case HashTypeSHA1:
            return CC_SHA1;
        case HashTypeSHA224:
            return CC_SHA224;
        case HashTypeSHA256:
            return CC_SHA256;
        case HashTypeSHA384:
            return CC_SHA384;
        case HashTypeSHA512:
            return CC_SHA512;
        default:
            return 0;
    }
}
