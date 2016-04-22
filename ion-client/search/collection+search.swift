//
//  collection+search.swift
//  ion-client
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

public extension IONCollection {
    
    /// Get a fulltext search handle
    ///
    /// - parameter callback: callback to be called if the search handle is ready
    public func getSearchHandle(callback: (Result<IONSearchHandle, IONError> -> Void)) {
        guard let searchIndex = ION.searchIndex(self.identifier) where ION.config.isFTSEnabled(self.identifier) else {
            callback(.Failure(.DidFail))
            return
        }
        
        func performCallback() {
            dispatch_async(self.workQueue) {
                guard let handle = IONSearchHandle(collection: self) else {
                    callback(.Failure(.DidFail))
                    return
                }
                
                callback(.Success(handle))
            }
        }
        
        if !NSFileManager.defaultManager().fileExistsAtPath(searchIndex) {
            ION.downloadFTSDB(self.identifier) {
                performCallback()
            }
        } else {
            performCallback()
        }
    }
}
