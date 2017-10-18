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
    public var serverURL: URL?

    /// locale-code to work on, defined by server config
    public var locale: String = "en_EN"

    /// set to `false` to disable logging (defaults to `true` in debug mode)
    public var loggingEnabled: Bool

    /// variation code to fetch from server, populated by default, only change if neccessary
    public var variation: String

    /// variation code to scale factor table
    public var variationScaleFactors: [String: CGFloat]

    /// response queue to run all async responses in, by default the main queue
    public var responseQueue = DispatchQueue.main

    /// global request progress handler (will be called periodically when progress updates)
    public var progressHandler: ((_ totalBytes: Int64, _ downloadedBytes: Int64, _ numberOfPendingDownloads: Int) -> Void)?

    /// the session token usually set by `ION.login` but may be overridden for custom login functionality
    public var sessionToken: String?

    /// Additional Headers that should be added to the requests
    fileprivate (set) var additionalHeaders: [String: String] = [:]

    /// last collection fetch, delete entry from dictionary to force a collection reload from server
    public var lastOnlineUpdate: [String: Date] = [:]

    /// collection cache timeout
    public var cacheTimeout: TimeInterval = 600

    /// offline mode: do not send any request
    public var offlineMode = false

    /// styling for attributed string conversion of markdown text
    public var stringStyling = AttributedStringStyling()

    /// ION Device ID, will be generated on first use
    public var deviceID: String {
        if let deviceID = UserDefaults.standard.string(forKey: "IONDeviceID") {
            return deviceID
        }

        let devID = UUID().uuidString
        UserDefaults.standard.set(devID as NSString, forKey: "IONDeviceID")
        UserDefaults.standard.synchronize()
        return devID
    }

    /// Needed to register additional content types with the default dispatcher
    public typealias ContentTypeLambda = ((JSONObject) throws -> IONContent)

    /// the alamofire manager to use for all calls, initialized to accept no cookies by default
    var alamofire: Alamofire.SessionManager?

    /// update detected blocks
    var updateBlocks: [String: ((String) -> Void)]

    /// Registered content types
    var registeredContentTypes = [String: ContentTypeLambda]()

    /// full text search settings
    fileprivate var ftsEnabled: [String: Bool]

    /// only the ION class may init this
    internal init() {
        let configuration: URLSessionConfiguration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.httpCookieAcceptPolicy = .never
        configuration.httpShouldSetCookies = false

        var protocolClasses = [AnyClass]()
        protocolClasses.append(IONCacheAvoidance.self)
        configuration.protocolClasses = protocolClasses

        #if DEBUG
            self.loggingEnabled = true
        #else
            self.loggingEnabled = false
        #endif

        self.updateBlocks = [String: ((String) -> Void)]()
        self.ftsEnabled = [String: Bool]()
        #if os(iOS)
            self.variation = NSString(format: "@%dx", Int(UIScreen.main.scale)) as String
        #else
            self.variation = "default"
        #endif
        self.variationScaleFactors = [ "default": CGFloat(1.0), "@1x": CGFloat(1.0), "@2x": CGFloat(2.0), "@3x": CGFloat(3.0) ]

        for (header, value) in Alamofire.SessionManager.defaultHTTPHeaders {
            self.additionalHeaders[header] = value
        }
        self.additionalHeaders["X-DeviceID"] = self.deviceID
        self.alamofire = Alamofire.SessionManager(configuration: configuration)
        if let alamofire = self.alamofire {
            alamofire.startRequestsImmediately = false
        }

        self.registerContentType(named: "colorcontent") { json in
            return try IONColorContent(json: json)
        }
        self.registerContentType(named: "connectioncontent") { json in
            return try IONConnectionContent(json: json)
        }
        self.registerContentType(named: "datetimecontent") { json in
            return try IONDateTimeContent(json: json)
        }
        self.registerContentType(named: "filecontent") { json in
            return try IONFileContent(json: json)
        }
        self.registerContentType(named: "flagcontent") { json in
            return try IONFlagContent(json: json)
        }
        self.registerContentType(named: "imagecontent") { json in
            return try IONImageContent(json: json)
        }
        self.registerContentType(named: "numbercontent") { json in
            return try IONNumberContent(json: json)
        }
        self.registerContentType(named: "mediacontent") { json in
            return try IONMediaContent(json: json)
        }
        self.registerContentType(named: "optioncontent") { json in
            return try IONOptionContent(json: json)
        }
        self.registerContentType(named: "textcontent") { json in
            return try IONTextContent(json: json)
        }

        self.registerUpdateBlock(identifier: "fts") { collectionIdentifier in
            if ION.config.isFTSEnabled(forCollection: collectionIdentifier) {
                ION.downloadFTSDB(forCollection: collectionIdentifier)
            }
        }
    }

    /// Register block to be called if something changed in a collection
    ///
    /// - parameter identifier: block identifier
    /// - parameter block:      block to call
    public mutating func registerUpdateBlock(identifier: String, block: @escaping ((String) -> Void)) {
        self.updateBlocks[identifier] = block
    }

    /// De-Register update notification block
    ///
    /// - parameter identifier: block identifier
    public mutating func removeUpdateBlock(identifier: String) {
        self.updateBlocks.removeValue(forKey: identifier)
    }

    /// Enable and prepare for Full text search for a collection (fetches additional data from server)
    ///
    /// - parameter collectionIdentifier: collection identifier
    public func prepareFTS(forCollection collectionIdentifier: String) {
        guard let searchIndex = ION.searchIndex(forCollection: collectionIdentifier) else {
            return
        }

        ION.config.enableFTS(forCollection: collectionIdentifier)

        if !FileManager.default.fileExists(atPath: searchIndex) {
            ION.downloadFTSDB(forCollection: collectionIdentifier)
        }
    }

    private mutating func enableFTS(forCollection collectionIdentifier: String) {
        self.ftsEnabled[collectionIdentifier] = true
    }

    /// Disable Full text search for a collection
    ///
    /// - parameter collectionIdentifier: collection identifier
    public mutating func disableFTS(forCollection collectionIdentifier: String) {
        self.ftsEnabled[collectionIdentifier] = false
    }

    /// Check if full text search is enabled for a collection
    ///
    /// - parameter collectionIdentifier: collection identifier
    ///
    /// - returns: true if fts is enabled
    public func isFTSEnabled(forCollection collectionIdentifier: String) -> Bool {
        return self.ftsEnabled[collectionIdentifier] ?? false
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
    public mutating func registerContentType(named typeName: String, creationBlock: @escaping ContentTypeLambda) {
        self.registeredContentTypes[typeName] = creationBlock
    }

    /// De-register custom content type
    ///
    /// - parameter typeName: type name in JSON
    public mutating func unRegisterContentType(named typeName: String) {
        self.registeredContentTypes.removeValue(forKey: typeName)
    }

    /// Set the credentials for HTTP Basic Authentication.
    /// Use either this, `sessionToken` or the `login()` call for authentication.
    ///
    /// - parameter user: The user
    /// - parameter password: The password
    public mutating func setBasicAuthCredentials(user: String, password: String) {
        let auth = "\(user):\(password)" as NSString

        guard let authData = auth.data(using: String.Encoding.utf8.rawValue) else {
            return
        }

        self.additionalHeaders["Authorization"] = "Basic " + authData.base64EncodedString(options: NSData.Base64EncodingOptions())
    }

    internal func cacheBehaviour(_ requestedBehaviour: IONCacheBehaviour) -> IONCacheBehaviour {
        if self.offlineMode {
            return .force
        }
        return requestedBehaviour
    }
}
