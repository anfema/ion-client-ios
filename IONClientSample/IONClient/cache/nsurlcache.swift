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


open class IONCacheAvoidance: URLProtocol {
    var session: Foundation.URLSession?
    var dataTask: URLSessionDataTask?

    open override class func canInit(with request: URLRequest) -> Bool {
        guard let serverURL = ION.config.serverURL else {
            return false
        }

        guard let url = request.url, url.absoluteString.hasPrefix(serverURL.absoluteString) else {
            return false
        }

        return true
    }

    open override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    open override class func requestIsCacheEquivalent(_ a: URLRequest, to b: URLRequest) -> Bool {
        return false
    }

    open override func startLoading() {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .useProtocolCachePolicy
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false

        self.session = Foundation.URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue.main)

        if let task = self.session?.dataTask(with: self.request) {
            self.dataTask = task
            task.resume()
        }
    }

    open override func stopLoading() {
        self.dataTask?.cancel()
    }
}

extension IONCacheAvoidance: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.client?.urlProtocol(self, didLoad: data)
    }
}

extension IONCacheAvoidance: URLSessionDelegate {
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            self.client?.urlProtocol(self, didFailWithError: error)
        } else {
            self.client?.urlProtocolDidFinishLoading(self)
        }
    }
}
