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
    /// - parameter callback: Callback to be called when the search handle is ready
    public func getSearchHandle(callback: (Result<IONSearchHandle, IONError> -> Void)) {
        guard let searchIndex = ION.searchIndex(self.identifier) where ION.config.isFTSEnabled(self.identifier) else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }

        // Anonymous function for calling callbacks
        func performCallback() {
            dispatch_async(self.workQueue) {
                guard let handle = IONSearchHandle(collection: self) else {
                    responseQueueCallback(callback, parameter: .Failure(.DidFail))
                    return
                }

                responseQueueCallback(callback, parameter: .Success(handle))
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
