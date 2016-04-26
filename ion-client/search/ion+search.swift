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
    
    internal class func searchIndex(collection: String) -> String? {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        return directoryURLs[0].URLByAppendingPathComponent("com.anfema.ion/fts-\(collection).sqlite3").path
    }
    
    internal class func downloadFTSDB(collection: String, callback:(Void -> Void)? = nil) {
        ION.collection(collection) { result in
            guard case .Success(let c) = result,
                  let ftsURL = c.ftsDownloadURL else {
                    // FIXME: What happens in error case?
                return
            }
            
            dispatch_barrier_async(c.workQueue) {
                let sema = dispatch_semaphore_create(0)
                
                IONRequest.fetchBinary(ftsURL, queryParameters: nil, cached: ION.config.cacheBehaviour(.Ignore), checksumMethod:"null", checksum: "") { result in
                    defer {
                        dispatch_semaphore_signal(sema)
                    }
                    
                    guard let searchIndex = ION.searchIndex(collection),
                          case .Success(let filename) = result else {
                        return
                    }
                    
                    if NSFileManager.defaultManager().fileExistsAtPath(searchIndex) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(searchIndex)
                        } catch {
                            if ION.config.loggingEnabled {
                                print("ION: Could not remove FTS db at '\(searchIndex)'")
                            }
                        }
                    }
                    
                    do {
                        try NSFileManager.defaultManager().moveItemAtPath(filename, toPath: searchIndex)
                    } catch {
                        if ION.config.loggingEnabled {
                            print("ION: Could not save FTS db at '\(searchIndex)'")
                        }
                    }
                }
                
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
                
                // Send notification that the fts db did change so that the search handlers can update their sqlite connection.
                NSNotificationCenter.defaultCenter().postNotificationName(IONFTSDBDidUpdateNotification, object: collection)
                
                if let callback = callback {
                    dispatch_async(ION.config.responseQueue) {
                        callback()
                    }
                }
            }
        }
    }
}