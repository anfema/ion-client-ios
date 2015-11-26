//
//  ampconfig.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation
import Alamofire
import Markdown

/// AMP configuration object
///
/// access with `AMP.config`
public struct AMPConfig {
    /// Server base URL for API (http://127.0.0.1:8000/client/v1/)
    public var serverURL:NSURL!
    
    /// locale-code to work on, defined by server config
    public var locale:String = "en_EN"
    
    /// variation code to fetch from server, populated by default, only change if neccessary
    public var variation:String
    
    /// variation code to scale factor table
    public var variationScaleFactors:[String:CGFloat]
    
    /// response queue to run all async responses in, by default a concurrent queue, may be set to main queue
    public var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
    
    /// global error handler (catches all errors that have not been caught by a `.onError` somewhere
    public var errorHandler:((String, AMPError) -> Void)!
    
    /// the session token usually set by `AMP.login` but may be overridden for custom login functionality
    public var sessionToken:String?
    
    /// last collection fetch, set to nil to force a collection reload from server
    public var lastOnlineUpdate: NSDate?
    
    /// collection cache timeout
    public var cacheTimeout: NSTimeInterval = 600
    
    /// styling for attributed string conversion of markdown text
    public var stringStyling = AttributedStringStyling()
    
    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    let alamofire: Alamofire.Manager
    
    /// update detected blocks
    var updateBlocks: [String:(String -> Void)]
    
    /// full text search settings
    private var ftsEnabled:[String:Bool]
    
    /// only the AMP class may init this
    internal init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.HTTPAdditionalHeaders = Alamofire.Manager.defaultHTTPHeaders
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        self.updateBlocks = Dictionary<String, (String -> Void)>()
        self.alamofire = Alamofire.Manager(configuration: configuration)
        self.ftsEnabled = [String:Bool]()
        #if os(iOS)
            self.variation = NSString(format: "@%dx", Int(UIScreen.mainScreen().scale)) as String
        #else
            self.variation = "default"
        #endif
        self.variationScaleFactors = [ "default": CGFloat(1.0), "@1x" : CGFloat(1.0), "@2x" : CGFloat(2.0), "@3x" : CGFloat(3.0) ]
        self.resetErrorHandler()
        
        self.registerUpdateBlock("fts") { collectionIdentifier in
            if AMP.config.isFTSEnabled(collectionIdentifier) {
                AMP.downloadFTSDB(collectionIdentifier)
            }
        }
    }
    
    /// Register block to be called if something changed in a collection
    ///
    /// - parameter identifier: block identifier
    /// - parameter block:      block to call
    public mutating func registerUpdateBlock(identifier: String, block: (String -> Void)) {
        self.updateBlocks[identifier] = block
    }
    
    /// De-Register update notification block
    ///
    /// - parameter identifier: block identifier
    public mutating func removeUpdateBlock(identifier: String) {
        self.updateBlocks.removeValueForKey(identifier)
    }
    
    /// Enable Full text search for a collection (fetches additional data from server)
    ///
    /// - parameter collection: collection identifier
    public mutating func enableFTS(collection: String) {
        self.ftsEnabled[collection] = true
        if !NSFileManager.defaultManager().fileExistsAtPath(AMP.searchIndex(collection)) {
            AMP.downloadFTSDB(collection)
        }
    }
    
    /// Disable Full text search for a collection
    ///
    /// - parameter collection: collection identifier
    public mutating func disableFTS(collection: String) {
        self.ftsEnabled[collection] = false
    }
    
    /// Check if full text search is enabled for a collection
    ///
    /// - parameter collection: collection identifier
    ///
    /// - returns: true if fts is enabled
    public func isFTSEnabled(collection: String) -> Bool {
        if let enabled = self.ftsEnabled[collection] {
            return enabled
        }
        return false
    }
    
    /// Reset the error handler to the default logging handler
    public mutating func resetErrorHandler() {
        self.errorHandler = { (collection, error) in
            print("AMP unhandled error in collection '\(collection)': \(error)")
        }
    }
}
