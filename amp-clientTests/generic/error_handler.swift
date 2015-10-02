import XCTest
@testable import ampclient

class errorHandlerTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testPageFetchDuplicatedErrorhandler() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            // this one should be overridden by the second one
            XCTFail()
            expectation.fulfill()
        }.onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
            
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageFetchDuplicatedErrorhandler2() {
        let expectation = self.expectationWithDescription("fetch page")
        var errorCount = 0
        
        AMP.collection("test").onError() { error in
            // this one should be overridden by the second one
            XCTFail()
        }.onError() { error in
            errorCount++
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            if errorCount == 2 {
                expectation.fulfill()
            }
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
        XCTAssertEqual(errorCount, 2)
    }

    func testPageFetchDuplicatedErrorhandler3() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            XCTFail()
        }.page("page_001") { page in
        }

        AMP.collection("test").onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageFetchDuplicatedErrorhandler4() {
        let expectation = self.expectationWithDescription("fetch page")
        var expectFail = true
        
        AMP.collection("test").onError() { error in
            if !expectFail {
                XCTFail()
            }
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }

        self.waitForExpectationsWithTimeout(3.0, handler: nil)

        let expectation2 = self.expectationWithDescription("fetch page")
        expectFail = false

        AMP.collection("test").onError() { error in
            if case .PageNotFound = error {
                // all ok, we expected this
            } else {
                XCTFail()
            }
            expectation2.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}
