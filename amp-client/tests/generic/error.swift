//
//  error.swift
//  amp-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)


import XCTest
@testable import ampclient

class errorTests: DefaultXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNoDataError() {
        XCTAssertNotNil(AMPError.NoData(nil).makeNSError())
    }

    func testInvalidJSONError() {
        XCTAssertNotNil(AMPError.InvalidJSON(nil).makeNSError())
    }

    func testJSONObjectExpectedError() {
        XCTAssertNotNil(AMPError.JSONObjectExpected(nil).makeNSError())
    }

    func testJSONArrayExpectedError() {
        XCTAssertNotNil(AMPError.JSONArrayExpected(nil).makeNSError())
    }

    func testJSONArrayOrObjectExpectedError() {
        XCTAssertNotNil(AMPError.JSONArrayOrObjectExpected(nil).makeNSError())
    }

    func testUnknownContentTypeaError() {
        XCTAssertNotNil(AMPError.UnknownContentType("xxx").makeNSError())
    }

    func testCollectionNotFoundError() {
        XCTAssertNotNil(AMPError.CollectionNotFound("unknown").makeNSError())
    }

    func testPageNotFoundError() {
        XCTAssertNotNil(AMPError.PageNotFound("unknown").makeNSError())
    }

    func testInvalidPageHierarchyError() {
        XCTAssertNotNil(AMPError.InvalidPageHierarchy(parent: "parent", child: "sibling").makeNSError())
    }

    func testOutletNotFoundError() {
        XCTAssertNotNil(AMPError.OutletNotFound("unknown").makeNSError())
    }
}