//
//  collection+search.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

public extension AMPCollection {
    public func getSearchHandle(callback: (AMPSearchHandle -> Void)) {
        guard AMP.config.isFTSEnabled(self.identifier) else {
            return
        }
        if !NSFileManager.defaultManager().fileExistsAtPath(AMP.searchIndex(self.identifier)) {
            AMP.downloadFTSDB(self.identifier) {
                dispatch_async(self.workQueue) {
                    if let handle = AMPSearchHandle(collection: self) {
                        callback(handle)
                    }
                }
            }
        } else {
            dispatch_async(self.workQueue) {
                if let handle = AMPSearchHandle(collection: self) {
                    callback(handle)
                }
            }
        }
    }
}
