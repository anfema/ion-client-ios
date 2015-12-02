//
//  nsurlcache.swift
//  mockingbird
//
//  Created by Johannes Schriewer on 01/12/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import DEjson

internal struct MockBundleEntry {
    var url:String!
    var queryParameters = [String:String]()
    var requestMethod   = "GET"
    
    var responseCode:Int = 200
    var responseHeaders  = [String:String]()
    var responseFile:String?
    var responseMime:String?
    
    init(json: JSONObject) throws {
        guard case .JSONDictionary(let dict) = json where (dict["request"] != nil && dict["response"] != nil),
              case .JSONDictionary(let request) = dict["request"]! where request["url"] != nil,
              case .JSONDictionary(let response) = dict["response"]! where response["code"] != nil,
              case .JSONString(let url) = request["url"]!,
              case .JSONNumber(let code) = response["code"]!
            else {
            throw MockingBird.Error.InvalidBundleDescriptionFile
        }
        
        self.url = url
        self.responseCode = Int(code)

        if let q = request["parameters"],
           case .JSONDictionary(let query) = q {
                for item in query {
                    if case .JSONString(let value) = item.1 {
                        self.queryParameters[item.0] = value
                    }
                }
        }
        
        if let q = request["method"],
            case .JSONString(let method) = q {
                self.requestMethod = method
        }

        if let q = response["headers"],
            case .JSONDictionary(let headers) = q {
                for item in headers {
                    if case .JSONString(let value) = item.1 {
                        self.responseHeaders[item.0] = value
                    }
                }
        }

        if let q = response["file"],
            case .JSONString(let file) = q {
                self.responseFile = file
        }
        
        if let q = response["mime_type"],
            case .JSONString(let mime) = q {
                self.responseMime = mime
        }
    }
}

public class MockingBird: NSURLProtocol {
    static var currentMockBundle: [MockBundleEntry]?
    static var currentMockBundlePath: String?
    
    public enum Error: ErrorType {
        case MockBundleNotFound
        case InvalidMockBundle
        case InvalidBundleDescriptionFile
    }
    
    /// Register MockingBird with a NSURLSession
    ///
    /// - parameter session: the session to mock
    public class func registerInSession(session: NSURLSession) {
        var protocolClasses = session.configuration.protocolClasses
        if protocolClasses == nil {
            protocolClasses = [AnyClass]()
        }
        protocolClasses!.insert(MockingBird.self, atIndex: 0)
        session.configuration.protocolClasses = protocolClasses
    }
    
    public class func setMockBundle(bundlePath: String) throws {
        do {
            var isDir:ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(bundlePath, isDirectory: &isDir) && isDir {
                let jsonString = try String(contentsOfFile: "\(bundlePath)/bundle.json")

                let jsonObject = JSONDecoder(jsonString).jsonObject
                if case .JSONArray(let array) = jsonObject {
                    self.currentMockBundle = try array.map { item -> MockBundleEntry in
                        return try MockBundleEntry(json: item)
                    }
                } else {
                    throw MockingBird.Error.InvalidBundleDescriptionFile
                }
            } else {
                throw MockingBird.Error.MockBundleNotFound
            }
        } catch MockingBird.Error.InvalidBundleDescriptionFile {
            throw MockingBird.Error.InvalidBundleDescriptionFile
        } catch {
            throw MockingBird.Error.InvalidMockBundle
        }
        self.currentMockBundlePath = bundlePath
    }
}

// MARK: - URL Protocol overrides
extension MockingBird {
    public override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        // we can only answer if we have a mockBundle
        if self.currentMockBundle == nil {
            return false
        }
        
        // we can answer all http and https requests
        if request.URL!.scheme.hasPrefix("http") {
            return true
        }
        return false
    }

    public override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        // canonical request is same as request
        return request
    }

    public override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        // nothing is cacheable
        return false
    }
    
    public override func startLoading() {
        var mime: String? = nil
        var data: NSData? = nil

        // find entry that matches
        for entry in MockingBird.currentMockBundle! {
            // url match
            if "\(self.request.URL!.scheme)\(entry.url)" == self.request.URL!.absoluteString {
                
                // request method match
                if entry.requestMethod == self.request.HTTPMethod {
                    
                    // components
                    var valid = false
                    if let components = self.request.URL!.query?.componentsSeparatedByString("&") {
                        for component in components {
                            let v = component.componentsSeparatedByString("=")
                            
                            for q in entry.queryParameters {
                                if q.0 == v[0] && q.1 == v[1] {
                                    valid = true
                                    break
                                }
                            }
                        }
                    } else {
                        // no components
                        if entry.queryParameters.count == 0 {
                            valid = true
                        }
                    }
                    
                    // if found entry
                    if valid {
                        
                        // set mime type
                        if let m = entry.responseMime {
                            mime = m
                        }
                        
                        // load data
                        if let f = entry.responseFile {
                            do {
                                data = try NSData(contentsOfFile: "\(MockingBird.currentMockBundlePath!)/\(f)", options: .DataReadingMappedIfSafe)
                            } catch {
                                data = nil
                            }
                        }
                        
                        break
                    }
                }
            }
        }
        
        
        // construct response
        var response: NSURLResponse
        if let data = data {
            response = NSURLResponse(URL: self.request.URL!, MIMEType: mime, expectedContentLength: data.length, textEncodingName: nil)
        } else {
            response = NSURLResponse(URL: self.request.URL!, MIMEType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
        
        // send response
        self.client!.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        
        // send response data if available
        if let data = data {
            self.client!.URLProtocol(self, didLoadData: data)
        }
        
        // finish up
        self.client!.URLProtocolDidFinishLoading(self)
    }
    
    public override func stopLoading() {
        // do nothing
    }
}
