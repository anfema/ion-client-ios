//
//  config.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import XCTest
@testable import ampclient

struct DefaultConfig {
    static let serverURL = "http://rodriguez.local:8000/client/v1/"
    static let locale    = "de_DE"
}



class DefaultXCTestCase: XCTestCase {

    func configure(callback: (Void -> Void)) {
        AMP.config.serverURL = NSURL(string: DefaultConfig.serverURL)
        AMP.config.locale = DefaultConfig.locale

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
