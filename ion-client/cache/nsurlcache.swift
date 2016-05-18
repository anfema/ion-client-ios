//
//  nsurlcache.swift
//  ion-client
//
//  Created by Johannes Schriewer on 01/12/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation


public class IONCacheAvoidance: NSURLProtocol {
    var session:NSURLSession?
    var dataTask:NSURLSessionDataTask?
    
    public override class func canInitWithRequest(request: NSURLRequest) -> Bool {
        guard let serverURL = ION.config.serverURL else {
            return false
        }
        
        guard request.URLString.hasPrefix(serverURL.URLString) else {
            return false
        }
        
        return true
    }

    public override class func canonicalRequestForRequest(request: NSURLRequest) -> NSURLRequest {
        return request
    }

    public override class func requestIsCacheEquivalent(a: NSURLRequest, toRequest b: NSURLRequest) -> Bool {
        return false
    }
    
    public override func startLoading() {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.requestCachePolicy = .UseProtocolCachePolicy
        config.HTTPCookieAcceptPolicy = .Never
        config.HTTPShouldSetCookies = false

        self.session = NSURLSession(configuration: config, delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        
        if let task = self.session?.dataTaskWithRequest(self.request) {
            self.dataTask = task
            task.resume()
        }
    }
    
    public override func stopLoading() {
        self.dataTask?.cancel()
    }
}

extension IONCacheAvoidance: NSURLSessionDataDelegate {
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.client?.URLProtocol(self, didReceiveResponse: response, cacheStoragePolicy: .NotAllowed)
        completionHandler(.Allow)
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        self.client?.URLProtocol(self, didLoadData: data)
    }
}

extension IONCacheAvoidance: NSURLSessionDelegate {
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        if let error = error {
            self.client?.URLProtocol(self, didFailWithError: error)
        } else {
            self.client?.URLProtocolDidFinishLoading(self)
        }
    }
}