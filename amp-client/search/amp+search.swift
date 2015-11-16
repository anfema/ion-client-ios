//
//  amp+search.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

internal extension AMP {
    
    internal class func searchIndex(collection: String) -> String {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.amp/fts-\(collection).sqlite3")
        return fileURL.path!
    }
    
    internal class func downloadFTSDB(collection: String, callback:(Void -> Void)? = nil) {
        AMP.collection(collection) { c in
            dispatch_barrier_async(c.workQueue) {
                let sema = dispatch_semaphore_create(0)
                
                var url:String = AMP.config.serverURL.absoluteString
                // TODO: Make fts db collection specific
                url = url.stringByReplacingOccurrencesOfString("client/v1/", withString: "protected_media/fts_db.sqlite3")
                AMPRequest.fetchBinary(url, queryParameters: nil, cached: false, checksumMethod:"null", checksum: "") { result in
                    defer {
                        dispatch_semaphore_signal(sema)
                    }
                    guard case .Success(let filename) = result else {
                        return
                    }
                    if NSFileManager.defaultManager().fileExistsAtPath(AMP.searchIndex(collection)) {
                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(AMP.searchIndex(collection))
                        } catch {
                            print("AMP: Could not remove FTS db at '\(AMP.searchIndex(collection))'")
                        }
                    }
                    do {
                        try NSFileManager.defaultManager().moveItemAtPath(filename, toPath: AMP.searchIndex(collection))
                    } catch {
                        print("AMP: Could not save FTS db at '\(AMP.searchIndex(collection))'")
                    }
                }
                
                dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER)
                if callback != nil {
                    callback!()
                }
            }
        }
    }
}