import XCTest
@testable import ampclient

class textContentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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