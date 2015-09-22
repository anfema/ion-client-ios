import XCTest
import Foundation
@testable import ampclient

class datetimeContentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
 
    
    func testDateOutletFetchSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.date("Datetime") {
                XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            } else {
                XCTFail("date content 'Datetime' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testDateOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").date("Datetime") { value in
            XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}