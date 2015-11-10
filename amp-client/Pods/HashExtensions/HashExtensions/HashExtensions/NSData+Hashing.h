//
//  NSData+NSData_Hashing.h
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

@interface NSData (Hashing)

- (NSString *)hexString;
- (NSData *)cryptoHash:(HashType)hash;
+ (NSData *)cryptoHashWithData:(NSData *)data hash:(HashType)hash;

@end
