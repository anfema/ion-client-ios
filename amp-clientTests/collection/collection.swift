import XCTest
@testable import ampclient

class collectionTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testCollectionFetch() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("test", callback: { collection in
            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }).onError({ error in
            XCTFail()
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("gnarf", callback:{ collection in
            XCTFail()
            expectation.fulfill()
        }).onError { error in
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}

