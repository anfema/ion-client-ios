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
    var collectionCache = Array<AMPCollection>()
    
    private init() {
        // do nothing but make init private
    }
}


public struct AMPConfig {
    var serverURL:NSURL!
    var locale:String = "en_EN"
    var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", nil)
}

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
    
    public class func registerProgress(progressObject: NSProgress, urlString: String) {
        // TODO: send progress callbacks
    }
    
    private init() {
        // factory only class
    }
}