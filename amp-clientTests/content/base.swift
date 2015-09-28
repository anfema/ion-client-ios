import XCTest
@testable import ampclient

class contentBaseTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("page_001"){ page in
            if let _ = page.outlet("Text") {
                // all ok
            } else {
                XCTFail("outlet for name 'text' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("page_001").outlet("Text") { text in
            XCTAssertNotNil(text)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}