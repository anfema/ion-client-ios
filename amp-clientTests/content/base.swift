import XCTest
@testable import ampclient

class contentBaseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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