import XCTest
@testable import ampclient

class textContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testTextOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let text = page.text("Text") {
                XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            } else {
                XCTFail("text content 'text' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testTextOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").text("Text") { text in
            XCTAssert(text.hasPrefix("Donec ullamcorper nulla non"))
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}