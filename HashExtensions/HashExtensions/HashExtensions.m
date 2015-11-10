//
//  HashExtensions.m
//  HashExtensions
//
//  Created by Johannes Schriewer on 10/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

#import <Foundation/Foundation.h>
#import "HashExtensions.h"

HashType hashTypeFromName(NSString *name) {
    NSString *lowercase = [name lowercaseString];
    if ([lowercase isEqualToString:@"md2"]) {
        return HashTypeMD2;
    }
    if ([lowercase isEqualToString:@"md4"]) {
        return HashTypeMD4;
    }
    if ([lowercase isEqualToString:@"md5"]) {
        return HashTypeMD5;
    }
    if ([lowercase isEqualToString:@"sha1"]) {
        return HashTypeSHA1;
    }
    if ([lowercase isEqualToString:@"sha224"]) {
        return HashTypeSHA224;
    }
    if ([lowercase isEqualToString:@"sha256"]) {
        return HashTypeSHA256;
    }
    if ([lowercase isEqualToString:@"sha384"]) {
        return HashTypeSHA384;
    }
    if ([lowercase isEqualToString:@"sha512"]) {
        return HashTypeSHA512;
    }
    return HashTypeInvalid;
}
