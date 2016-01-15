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
import anfema_mockingbird
import Alamofire
@testable import amp_client


struct DefaultConfig {
    static let serverURL = "http://127.0.0.1:8000/client/v1/"
    static let locale    = "de_DE"
}



class DefaultXCTestCase: XCTestCase {
    let mock = true

    func configure(callback: (Void -> Void)) {
        AMP.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        AMP.config.locale = DefaultConfig.locale
        AMP.config.responseQueue = dispatch_queue_create("com.anfema.amp.responsequeue.test", DISPATCH_QUEUE_SERIAL)
        AMP.config.variation = "default"
        
        dispatch_async(AMP.config.responseQueue) {
            callback()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        let expectation = self.expectationWithDescription("login")
        self.configure() {
            
            if self.mock {
                let config = AMP.config.alamofire.session.configuration
                MockingBird.registerInConfig(config)
                AMP.config.alamofire = Alamofire.Manager(configuration: config)
                
                let path = NSBundle(forClass: self.dynamicType).resourcePath! + "/bundles/amp"
                do {
                    try MockingBird.setMockBundle(path)
                } catch {
                    XCTFail("Could not set up API mocking")
                }
            }

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
