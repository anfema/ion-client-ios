//
//  config.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import XCTest
import anfema_mockingbird
import Alamofire
@testable import ion_client


struct DefaultConfig {
    static let serverURL = "http://127.0.0.1:8000/client/v1/"
    static let locale    = "de_DE"
}



class DefaultXCTestCase: XCTestCase {
    let mock = true

    func configure(callback: (Void -> Void)) {
        ION.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        ION.config.locale = DefaultConfig.locale
        ION.config.responseQueue = dispatch_queue_create("com.anfema.ion.responsequeue.test", DISPATCH_QUEUE_SERIAL)
        ION.config.variation = "default"
        
        dispatch_async(ION.config.responseQueue) {
            callback()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        let expectation = self.expectationWithDescription("login")
        self.configure() {
            
            if self.mock {
                let config = ION.config.alamofire.session.configuration
                MockingBird.registerInConfig(config)
                ION.config.alamofire = Alamofire.Manager(configuration: config)
                
                let path = NSBundle(forClass: self.dynamicType).resourcePath! + "/bundles/ion"
                do {
                    try MockingBird.setMockBundle(path)
                } catch {
                    XCTFail("Could not set up API mocking")
                }
            }

            expectation.fulfill()
        }

        //ION.resetMemCache()
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}

class LoggedInXCTestCase: DefaultXCTestCase {
    override func configure(callback: (Void -> Void)) {
        ION.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        ION.config.locale = DefaultConfig.locale
        
        // setup sessionToken
        if let _ = ION.config.sessionToken {
            // already logged in
            dispatch_async(ION.config.responseQueue) {
                callback()
            }
        } else {
            print("ION Test: Logging in")
            ION.login("admin@anfe.ma", password: "test") { success in
                if success {
                    print("ION Test: Login successful")
                } else {
                    print("ION Test: Login failed")
                }
                callback()
            }
        }
    }
}
