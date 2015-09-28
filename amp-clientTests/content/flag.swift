import XCTest
@testable import ampclient

class flagContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFlagOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.isSet("Flag") {
                XCTAssertEqual(value, false)
            } else {
                XCTFail("flag content 'Flag' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testFlagOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").isSet("Flag") { value in
            XCTAssertEqual(value, false)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}