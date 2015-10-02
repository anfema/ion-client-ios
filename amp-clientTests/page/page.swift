import XCTest
@testable import ampclient

class pageTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPageFetchSync() {
        let expectation = self.expectationWithDescription("fetch page")
        AMP.resetMemCache()
        
        AMP.collection("test") { collection in
            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssertTrue(page.isProxy)
            XCTAssert(page.identifier == "page_001")
            expectation.fulfill()
        }.onError() { error in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            XCTFail()
            expectation.fulfill()
        }.page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageFetchFail() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            if case .PageNotFound(let name) = error {
                XCTAssertEqual(name, "unknown_page")
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

}
