//
//  ionconfig.swift
//  ion-client
//
//  Created by Johannes Schriewer on 16/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import Foundation
import Alamofire
import UIKit.UIScreen

/// ION caching object
///
/// access with `ION.config.caching`
public struct IONCaching {

    /// Directory that will be used for caching. Default is set to `cachesDirectory`.
    /// If `cacheDirectory` changed by host-app, app has to be re-installed or at least the ION-Client data has to be cleared completely.
    public var cacheDirectory: FileManager.SearchPathDirectory = .cachesDirectory

    /// FileProtectionLevel that will be used. Default is set to `none`.
    /// If `protectionLevel` changed by host-app, app has to be re-installed or at least the ION-Client data has to be cleared completely.
    public var protectionLevel: FileProtectionType = .none

    /// Collection cache timeout. Default is set to `600`.
    public var cacheTimeout: TimeInterval = 600

    /// Determines if cache should be excluded from backup. Default is set to `false`.
    /// If `excludeFromBackup` changed by host-app, app has to be re-installed or at least the ION-Client data has to be cleared completely.
    public var excludeFromBackup: Bool = false

    /// Generates file attributes based on specified file protection level.
    private var fileAttributes: [FileAttributeKey: Any]? {

        guard protectionLevel != .none else { return nil }

        return [FileAttributeKey.protectionKey: protectionLevel]
    }


    /// Only the ION class may init this.
    internal init() {
    }


    /// Creates a directory if required taking protection level and backup strategy into account.
    internal func createDirectoryIfNecessary(atPath path: String) throws {

        if !FileManager.default.fileExists(atPath: path) {
            try FileManager.default.createDirectory(atPath: path,
                                                    withIntermediateDirectories: true,
                                                    attributes: ION.config.caching.fileAttributes)

            try excludeFileFromBackupIfNecessary(filePath: path)
        }
    }


    /// Marks a file or directory as excluded from backup if required.
    internal func excludeFileFromBackupIfNecessary(filePath path: String) throws {

        guard excludeFromBackup == true else { return }

        var url = URL(fileURLWithPath: path)
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try url.setResourceValues(resourceValues)
    }
}

/// ION configuration object
///
/// access with `ION.config`
public struct IONConfig {

    /// Caching preferences
    public var caching: IONCaching = IONCaching()

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
    public var variationScaleFactors: [String: Double]

    /// response queue to run all async responses in, by default the main queue
    public var responseQueue = DispatchQueue.main

    /// global request progress handler (will be called periodically when progress updates)
    public var progressHandler: ((_ totalBytes: Int64, _ downloadedBytes: Int64, _ numberOfPendingDownloads: Int) -> Void)?

    /// the session token usually set by `ION.login` but may be overridden for custom login functionality.
    /// Take a look at `authorizationHeaderValue` when a more custom auth method is required.
    public var sessionToken: String?

    /// a custom authorization header value that can be used for custom login functionality
    /// - warning: sessionToken will be ignored if set
    public var authorizationHeaderValue: String?

    /// Additional Headers that should be added to the requests
    fileprivate (set) var additionalHeaders: [String: String] = [:]

    /// last collection fetch, delete entry from dictionary to force a collection reload from server
    public var lastOnlineUpdate: [String: Date] = [:]

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

    typealias UpdateBlock = (String) -> Void

    /// update detected blocks
    var updateBlocks: [String: UpdateBlock]

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

        self.updateBlocks = [:]

        self.ftsEnabled = [String: Bool]()
        self.variation = NSString(format: "@%dx", Int(UIScreen.main.scale)) as String
        self.variationScaleFactors = [ "default": 1.0, "@1x": 1.0, "@2x": 2.0, "@3x": 3.0 ]

        Alamofire.SessionManager.defaultHTTPHeaders
            .forEach({ self.additionalHeaders[$0.key] = $0.value })
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

        self.registerContentType(named: "tablecontent") { json in
            return try IONTableContent(json: json)
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


    /// Sets custom headers that should be added to each ion request.
    /// E.g. to implement killswitch functionalitly.
    /// - Parameter headers: The dictionary of custom headers.
    public mutating func setCustomHeaders(_ headers: [String: String]) {
        headers.forEach({ self.additionalHeaders[$0.key] = $0.value })
    }

    internal func cacheBehaviour(_ requestedBehaviour: IONCacheBehaviour) -> IONCacheBehaviour {
        if self.offlineMode {
            return .force
        }
        return requestedBehaviour
    }
}
