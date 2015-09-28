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
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}
