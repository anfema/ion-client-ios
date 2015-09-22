import XCTest
@testable import ampclient

class colorContentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testColorOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.color("Color") {
                var r:CGFloat = 0.0
                var g:CGFloat = 0.0
                var b:CGFloat = 0.0
                var a:CGFloat = 0.0
                value.getRed(&r, green: &g, blue: &b, alpha: &a)
                XCTAssertEqual(r,   0.0 / 255.0)
                XCTAssertEqual(g,   0.0 / 255.0)
                XCTAssertEqual(b, 255.0 / 255.0)
                XCTAssertEqual(a, 255.0 / 255.0)
            } else {
                XCTFail("color content 'Color' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testColorOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").color("Color") { value in
            var r:CGFloat = 0.0
            var g:CGFloat = 0.0
            var b:CGFloat = 0.0
            var a:CGFloat = 0.0
            value.getRed(&r, green: &g, blue: &b, alpha: &a)
            XCTAssertEqual(r,   0.0 / 255.0)
            XCTAssertEqual(g,   0.0 / 255.0)
            XCTAssertEqual(b, 255.0 / 255.0)
            XCTAssertEqual(a, 255.0 / 255.0)

            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}