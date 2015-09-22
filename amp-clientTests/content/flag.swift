import XCTest
@testable import ampclient

class flagContentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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