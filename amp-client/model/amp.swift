//
//  amp.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

private class AMPMemCache {
    static let sharedInstance = AMPMemCache()
    var collectionCache = [AMPCollection]()
    
    private init() {
        // do nothing but make init private
    }
}


public struct AMPConfig {
    var serverURL:NSURL!
    var locale:String = "en_EN"
    var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", nil)
}


/// AMP base class, almost everything will start here
///
/// Documentation missing, so here's a picture of a cat:
/// ![cat](http://lorempixel.com/300/200/cats/)
public class AMP {
    static var config = AMPConfig()
    
    public class func collection(identifier: String) -> AMPCollection {
        for c in AMPMemCache.sharedInstance.collectionCache {
            if c.identifier == identifier {
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale)
        AMPMemCache.sharedInstance.collectionCache.append(newCollection)
        return newCollection
    }
    
    public class func collection(identifier: String, callback: (AMPCollection -> Void)) -> AMPCollection {
        for c in AMPMemCache.sharedInstance.collectionCache {
            if c.identifier == identifier {
                callback(c)
                return c
            }
        }
        let newCollection = AMPCollection(identifier: identifier, locale: AMP.config.locale, callback:callback)
        AMPMemCache.sharedInstance.collectionCache.append(newCollection)
        return newCollection
    }
    
    public class func resetMemCache() {
        AMPMemCache.sharedInstance.collectionCache.removeAll()
    }
    
    public class func resetDiskCache() {
        AMPRequest.resetCache(self.config.serverURL!.host!)
    }
    
    public class func refreshCache(callback: (AMPCollection -> Void)) {
       
        let queue = dispatch_queue_create("com.anfema.amp.CacheRefresh", nil)
        dispatch_suspend(queue)
        for index in AMPMemCache.sharedInstance.collectionCache.indices {
            let collection = AMPMemCache.sharedInstance.collectionCache[index]
            let name = collection.identifier

            dispatch_async(queue) {
                let locale = collection.locale
                
                // reinitialize cached collection, turning cache off for this call
                let _ = AMPCollection(identifier: name, locale: locale, useCache: false) { collection in
                    AMPMemCache.sharedInstance.collectionCache.replaceRange(Range<Int>(start: index, end: index + 1), with: [collection])
                    callback(collection)
                }
            }
            
            for page in collection.pageCache {
                dispatch_async(queue) {
                    AMP.collection(name) { collection in
                        for p in collection.pages {
                            if (p.identifier == page.identifier) && (p.lastChanged.compare(page.lastUpdate) != .OrderedAscending) {
                                collection.page(page.identifier) { page in
                                    // do nothing, just download page
                                    print("AMP: Page refreshed: \(collection.identifier) -> \(page.identifier)")
                                }
                            } else {
                                print("AMP: Page current: \(collection.identifier) -> \(page.identifier)")
                            }
                        }
                    }
                }
            }
        }
        dispatch_resume(queue)
    }
    
    public class func registerProgress(progressObject: NSProgress, urlString: String) {
        // TODO: send progress callbacks
    }
    
    private init() {
        // factory only class
    }
}