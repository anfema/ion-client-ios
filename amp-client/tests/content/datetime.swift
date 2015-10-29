import XCTest
import Foundation
@testable import ampclient

class datetimeContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
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
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testDateOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").date("Datetime") { value in
            XCTAssert(value.compare(NSDate(timeIntervalSince1970: 443795696)) == NSComparisonResult.OrderedSame)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
}