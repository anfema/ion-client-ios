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
    
    func configure(_ callback: @escaping ((Void) -> Void)) {
        ION.config.serverURL = URL(string: DefaultConfig.serverURL)
        ION.config.locale = DefaultConfig.locale
        ION.config.responseQueue = DispatchQueue(label: "com.anfema.ion.responsequeue.test", attributes: [])
        ION.config.variation = "default"
        
        (ION.config.responseQueue).async {
            callback()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        let expectation = self.expectation(description: "login")
        self.configure() {
            
            if self.mock {
                let config = ION.config.alamofire!.session.configuration
                MockingBird.registerInConfig(config)
                ION.config.alamofire = Alamofire.SessionManager(configuration: config)
                
                let path = Bundle(for: type(of: self)).resourcePath! + "/bundles/ion"
                do {
                    try MockingBird.setMockBundle(path)
                } catch {
                    XCTFail("Could not set up API mocking")
                }
            }

            expectation.fulfill()
        }

        //ION.resetMemCache()
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
}


var currentQueueLabel : String?{
    let label = __dispatch_queue_get_label(nil)
    return String(cString: label, encoding: .utf8)
}


class LoggedInXCTestCase: DefaultXCTestCase {
    override func configure(_ callback: @escaping ((Void) -> Void)) {
        ION.config.serverURL = URL(string: DefaultConfig.serverURL)
        ION.config.locale = DefaultConfig.locale
        
        // setup sessionToken
        if let _ = ION.config.sessionToken {
            // already logged in
            (ION.config.responseQueue).async {
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
