//
//  HashExtensions.h
//  HashExtensions
//
//  Created by Johannes Schriewer on 10/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

#import <Foundation/Foundation.h>

//! Project version number for HashExtensions.
FOUNDATION_EXPORT double HashExtensionsVersionNumber;

//! Project version string for HashExtensions.
FOUNDATION_EXPORT const unsigned char HashExtensionsVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <HashExtensions/PublicHeader.h>

typedef NS_ENUM(NSInteger, HashType) {
    HashTypeMD2 = 0,
    HashTypeMD4,
    HashTypeMD5,
    HashTypeSHA1,
    HashTypeSHA224,
    HashTypeSHA256,
    HashTypeSHA384,
    HashTypeSHA512,
    HashTypeInvalid = NSIntegerMax
};

HashType hashTypeFromName(NSString *name);

#import "NSData+Hashing.h"
#import "NSString+Hashing.h"