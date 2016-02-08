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
import DEjson

/// AMP configuration object
///
/// access with `AMP.config`
public struct AMPConfig {
    /// Server base URL for API (http://127.0.0.1:8000/client/v1/)
    public var serverURL:NSURL!
    
    /// locale-code to work on, defined by server config
    public var locale:String = "en_EN"
    
    /// set to `false` to disable logging (defaults to `true` in debug mode)
    public var loggingEnabled:Bool
    
    /// variation code to fetch from server, populated by default, only change if neccessary
    public var variation:String
    
    /// variation code to scale factor table
    public var variationScaleFactors:[String:CGFloat]
    
    /// response queue to run all async responses in, by default a concurrent queue, may be set to main queue
    public var responseQueue = dispatch_queue_create("com.anfema.amp.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
    
    /// global error handler (catches all errors that have not been caught by a `.onError` somewhere)
    public var errorHandler:((String, AMPError) -> Void)!
    
    /// global request progress handler (will be called periodically when progress updates)
    public var progressHandler:((totalBytes: Int64, downloadedBytes: Int64, numberOfPendingDownloads: Int) -> Void)?
    
    /// the session token usually set by `AMP.login` but may be overridden for custom login functionality
    public var sessionToken:String?
    
    /// Additional Headers that should be added to the requests
    private (set) var additionalHeaders: [String: String] = [:]
    
    /// last collection fetch, delete entry from dictionary to force a collection reload from server
    public var lastOnlineUpdate: [String: NSDate] = [:]
    
    /// collection cache timeout
    public var cacheTimeout: NSTimeInterval = 600
    
    /// styling for attributed string conversion of markdown text
    public var stringStyling = AttributedStringStyling()
    
    /// AMP Device ID, will be generated on first use
    public var deviceID:String {
        if let deviceID = NSUserDefaults.standardUserDefaults().stringForKey("AMPDeviceID") {
            return deviceID
        }
        
        let devID = NSUUID().UUIDString
        NSUserDefaults.standardUserDefaults().setObject(devID as NSString, forKey: "AMPDeviceID")
        NSUserDefaults.standardUserDefaults().synchronize()
        return devID
    }
    
    /// Needed to register additional content types with the default dispatcher
    public typealias ContentTypeLambda = (JSONObject throws -> AMPContent)

    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    var alamofire: Alamofire.Manager! = nil
    
    /// update detected blocks
    var updateBlocks: [String:(String -> Void)]

    /// Registered content types
    var registeredContentTypes = [String:ContentTypeLambda]()

    /// full text search settings
    private var ftsEnabled:[String:Bool]
    
    /// only the AMP class may init this
    internal init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        var protocolClasses = [AnyClass]()
        protocolClasses.append(AMPCacheAvoidance)
        configuration.protocolClasses = protocolClasses
        
        #if DEBUG
            self.loggingEnabled = true
        #else
            self.loggingEnabled = false
        #endif
        
        self.updateBlocks = Dictionary<String, (String -> Void)>()
        self.ftsEnabled = [String:Bool]()
        #if os(iOS)
            self.variation = NSString(format: "@%dx", Int(UIScreen.mainScreen().scale)) as String
        #else
            self.variation = "default"
        #endif
        self.variationScaleFactors = [ "default": CGFloat(1.0), "@1x" : CGFloat(1.0), "@2x" : CGFloat(2.0), "@3x" : CGFloat(3.0) ]

        for (header, value) in Alamofire.Manager.defaultHTTPHeaders {
            self.additionalHeaders[header] = value
        }
        self.additionalHeaders["X-DeviceID"] = self.deviceID
        self.alamofire = Alamofire.Manager(configuration: configuration)
        self.resetErrorHandler()
        
        self.registerContentType("colorcontent") { json in
            return try AMPColorContent(json: json)
        }
        self.registerContentType("connectioncontent") { json in
            return try AMPConnectionContent(json: json)
        }
        self.registerContentType("datetimecontent") { json in
            return try AMPDateTimeContent(json: json)
        }
        self.registerContentType("filecontent") { json in
            return try AMPFileContent(json: json)
        }
        self.registerContentType("flagcontent") { json in
            return try AMPFlagContent(json: json)
        }
        self.registerContentType("imagecontent") { json in
            return try AMPImageContent(json: json)
        }
        self.registerContentType("numbercontent") { json in
            return try AMPNumberContent(json: json)
        }
        self.registerContentType("mediacontent") { json in
            return try AMPMediaContent(json: json)
        }
        self.registerContentType("optioncontent") { json in
            return try AMPOptionContent(json: json)
        }
        self.registerContentType("textcontent") { json in
            return try AMPTextContent(json: json)
        }
        
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
    
    /// Register a custom content type
    ///
    /// Example:
    ///
    /// AMP.config.registerContentType("customcontent") { json in
    ///     return try MyContent(json: json)
    /// }
    ///
    /// - parameter typeName: type name in JSON
    /// - parameter creationBlock: a block to create an instance of the content type
    public mutating func registerContentType(typeName: String, creationBlock: ContentTypeLambda) {
        self.registeredContentTypes[typeName] = creationBlock
    }
    
    /// De-register custom content type
    ///
    /// - parameter typeName: type name in JSON
    public mutating func unRegisterContentType(typeName: String) {
        self.registeredContentTypes.removeValueForKey(typeName)
    }
    
    /// Reset the error handler to the default logging handler
    public mutating func resetErrorHandler() {
        self.errorHandler = { (collection, error) in
            if AMP.config.loggingEnabled {
                print("AMP unhandled error in collection '\(collection)': \(error)")
            }
        }
    }
    
    /// Set the credentials for HTTP Basic Authentication.
    /// Use either this, `sessionToken` or the `login()` call for authentication.
    ///
    /// - parameter user: The user
    /// - parameter password: The password
    public mutating func setBasicAuthCredentials(user user: String, password: String) {
        let auth = "\(user):\(password)" as NSString
        let authData = auth.dataUsingEncoding(NSUTF8StringEncoding)!
        
        self.additionalHeaders["Authorization"] = "Basic " + authData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
}
