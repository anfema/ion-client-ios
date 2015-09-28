import XCTest
@testable import ampclient

class imageContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testImageOutletFetchAsyncCGImage() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").image("Image") { image in
            XCTAssertNotNil(image)
            XCTAssertEqual(CGSize(width: 600, height: 400), image.size)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(13.0, handler: nil)
    }
    
}