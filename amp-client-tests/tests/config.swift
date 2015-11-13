//
//  config.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import XCTest
@testable import amp_client

struct DefaultConfig {
    static let serverURL = "http://rodriguez.local:8000/client/v1/"
    static let locale    = "de_DE"
}



class DefaultXCTestCase: XCTestCase {

    func configure(callback: (Void -> Void)) {
        AMP.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        AMP.config.locale = DefaultConfig.locale
        AMP.config.responseQueue = dispatch_queue_create("com.anfema.amp.responsequeue.test", DISPATCH_QUEUE_SERIAL)
        
        dispatch_async(AMP.config.responseQueue) {
            callback()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        let expectation = self.expectationWithDescription("login")
        self.configure() {
            expectation.fulfill()
        }

        //AMP.resetMemCache()
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

class LoggedInXCTestCase: DefaultXCTestCase {
    override func configure(callback: (Void -> Void)) {
        AMP.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        AMP.config.locale = DefaultConfig.locale
        
        // setup sessionToken
        if let _ = AMP.config.sessionToken {
            // already logged in
            dispatch_async(AMP.config.responseQueue) {
                callback()
            }
        } else {
            print("AMP Test: Logging in")
            AMP.login("admin@anfe.ma", password: "test") { success in
                if success {
                    print("AMP Test: Login successful")
                } else {
                    print("AMP Test: Login failed")
                }
                callback()
            }
        }
    }
}