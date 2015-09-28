import XCTest
@testable import ampclient

class memcacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionMemcache() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            let collection2 = AMP.collection("test")
            XCTAssert(collection2 === collection)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }   
}
