//
//  ionconfig.swift
//  ion-client
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation
import Alamofire
import Markdown
import DEjson

/// ION configuration object
///
/// access with `ION.config`
public struct IONConfig {
    
    /// The scheme used to create the URLs provided by IONConnectionContent outlets
    public var connectionScheme = "ion"
    
    /// Server base URL for API (http://127.0.0.1:8000/client/v1/)
    public var serverURL:NSURL?
    
    /// locale-code to work on, defined by server config
    public var locale:String = "en_EN"
    
    /// set to `false` to disable logging (defaults to `true` in debug mode)
    public var loggingEnabled:Bool
    
    /// variation code to fetch from server, populated by default, only change if neccessary
    public var variation:String
    
    /// variation code to scale factor table
    public var variationScaleFactors:[String:CGFloat]
    
    /// response queue to run all asynchronous responses in, by default a concurrent queue, may be set to main queue
    public var responseQueue = dispatch_queue_create("com.anfema.ion.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
    
    /// global request progress handler (will be called periodically when progress updates)
    public var progressHandler:((totalBytes: Int64, downloadedBytes: Int64, numberOfPendingDownloads: Int) -> Void)?
    
    /// the session token usually set by `ION.login` but may be overridden for custom login functionality
    public var sessionToken:String?
    
    /// Additional Headers that should be added to the requests
    private (set) var additionalHeaders: [String: String] = [:]
    
    /// last collection fetch, delete entry from dictionary to force a collection reload from server
    public var lastOnlineUpdate: [String: NSDate] = [:]
    
    /// collection cache timeout
    public var cacheTimeout: NSTimeInterval = 600
    
    /// offline mode: do not send any request
    public var offlineMode = false
    
    /// styling for attributed string conversion of markdown text
    public var stringStyling = AttributedStringStyling()
    
    /// ION Device ID, will be generated on first use
    public var deviceID:String {
        if let deviceID = NSUserDefaults.standardUserDefaults().stringForKey("IONDeviceID") {
            return deviceID
        }
        
        let devID = NSUUID().UUIDString
        NSUserDefaults.standardUserDefaults().setObject(devID as NSString, forKey: "IONDeviceID")
        NSUserDefaults.standardUserDefaults().synchronize()
        return devID
    }
    
    /// Needed to register additional content types with the default dispatcher
    public typealias ContentTypeLambda = (JSONObject throws -> IONContent)

    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    var alamofire: Alamofire.Manager? = nil
    
    /// update detected blocks
    var updateBlocks: [String:(String -> Void)]

    /// Registered content types
    var registeredContentTypes = [String:ContentTypeLambda]()

    /// full text search settings
    private var ftsEnabled:[String:Bool]
    
    /// only the ION class may init this
    internal init() {
        let configuration: NSURLSessionConfiguration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.requestCachePolicy = .ReloadIgnoringLocalCacheData
        configuration.HTTPCookieAcceptPolicy = .Never
        configuration.HTTPShouldSetCookies = false
        
        var protocolClasses = [AnyClass]()
        protocolClasses.append(IONCacheAvoidance)
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
        if let alamofire = self.alamofire {
            alamofire.startRequestsImmediately = false
        }

        self.registerContentType("colorcontent") { json in
            return try IONColorContent(json: json)
        }
        self.registerContentType("connectioncontent") { json in
            return try IONConnectionContent(json: json)
        }
        self.registerContentType("datetimecontent") { json in
            return try IONDateTimeContent(json: json)
        }
        self.registerContentType("filecontent") { json in
            return try IONFileContent(json: json)
        }
        self.registerContentType("flagcontent") { json in
            return try IONFlagContent(json: json)
        }
        self.registerContentType("imagecontent") { json in
            return try IONImageContent(json: json)
        }
        self.registerContentType("numbercontent") { json in
            return try IONNumberContent(json: json)
        }
        self.registerContentType("mediacontent") { json in
            return try IONMediaContent(json: json)
        }
        self.registerContentType("optioncontent") { json in
            return try IONOptionContent(json: json)
        }
        self.registerContentType("textcontent") { json in
            return try IONTextContent(json: json)
        }
        
        self.registerUpdateBlock("fts") { collectionIdentifier in
            if ION.config.isFTSEnabled(collectionIdentifier) {
                ION.downloadFTSDB(collectionIdentifier)
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
        guard let searchIndex = ION.searchIndex(collection) else {
            return
        }
        self.ftsEnabled[collection] = true
        if !NSFileManager.defaultManager().fileExistsAtPath(searchIndex) {
            ION.downloadFTSDB(collection)
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
    ///     ION.config.registerContentType("customcontent") { json in
    ///         return try MyContent(json: json)
    ///     }
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
    
    /// Set the credentials for HTTP Basic Authentication.
    /// Use either this, `sessionToken` or the `login()` call for authentication.
    ///
    /// - parameter user: The user
    /// - parameter password: The password
    public mutating func setBasicAuthCredentials(user user: String, password: String) {
        let auth = "\(user):\(password)" as NSString
        
        guard let authData = auth.dataUsingEncoding(NSUTF8StringEncoding) else {
            return
        }
        
        self.additionalHeaders["Authorization"] = "Basic " + authData.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
    }
    
    internal func cacheBehaviour(requestedBehaviour: IONCacheBehaviour) -> IONCacheBehaviour {
        if self.offlineMode {
            return .Force
        }
        return requestedBehaviour
    }
}
