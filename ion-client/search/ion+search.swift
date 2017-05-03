//
//  ion+search.swift
//  ion-client
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

internal extension ION {

    internal class func searchIndex(forCollection collection: String) -> String? {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        return directoryURLs[0].appendingPathComponent("com.anfema.ion/fts-\(collection).sqlite3").path
    }

    internal class func downloadFTSDB(forCollection collection: String, callback: ((Void) -> Void)? = nil) {
        ION.collection(collection) { result in
            guard case .success(let c) = result,
                  let ftsURL = c.ftsDownloadURL else {
                    // FIXME: What happens in error case?
                return
            }

            c.workQueue.async(flags: .barrier, execute: {
                let sema = DispatchSemaphore(value: 0)

                IONRequest.fetchBinary(fromURL: ftsURL, queryParameters: nil, cacheBehaviour: ION.config.cacheBehaviour(.ignore), checksumMethod: "null", checksum: "") { result in
                    defer {
                        sema.signal()
                    }

                    guard let searchIndex = ION.searchIndex(forCollection: collection),
                          case .success(let filename) = result else {
                        return
                    }

                    if FileManager.default.fileExists(atPath: searchIndex) {
                        do {
                            try FileManager.default.removeItem(atPath: searchIndex)
                        } catch {
                            if ION.config.loggingEnabled {
                                print("ION: Could not remove FTS db at '\(searchIndex)'")
                            }
                        }
                    }

                    do {
                        try FileManager.default.moveItem(atPath: filename, toPath: searchIndex)
                    } catch {
                        if ION.config.loggingEnabled {
                            print("ION: Could not save FTS db at '\(searchIndex)'")
                        }
                    }
                }

                _ = sema.wait(timeout: DispatchTime.distantFuture)

                // Send notification that the fts db did change so that the search handlers can update their sqlite connection.
                NotificationCenter.default.post(name: Notification.ftsDatabaseDidUpdate, object: collection)

                ION.config.responseQueue.async {
                    callback?()
                }
            })
        }
    }
}
