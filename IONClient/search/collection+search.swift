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

extension IONCollection {

    /// Get a fulltext search handle
    ///
    /// - parameter callback: Callback to be called when the search handle is ready
    public func getSearchHandle(_ callback: @escaping ((Result<IONSearchHandle, Error>) -> Void)) {
        guard let searchIndex = ION.searchIndex(forCollection: self.identifier), ION.config.isFTSEnabled(forCollection: self.identifier) else {
            responseQueueCallback(callback, parameter: .failure(IONError.didFail))
            return
        }

        // Anonymous function for calling callbacks
        func performCallback() {
            self.workQueue.async {
                guard let handle = IONSearchHandle(collection: self) else {
                    responseQueueCallback(callback, parameter: .failure(IONError.didFail))
                    return
                }

                responseQueueCallback(callback, parameter: .success(handle))
            }
        }

        if !FileManager.default.fileExists(atPath: searchIndex) {
            ION.downloadFTSDB(forCollection: self.identifier) {
                performCallback()
            }
        } else {
            performCallback()
        }
    }
}
