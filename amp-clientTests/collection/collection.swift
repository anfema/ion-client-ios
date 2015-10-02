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
        
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection)
            XCTAssert(collection.identifier == "test")
            expectation.fulfill()
        }.onError({ error in
            XCTFail()
            expectation.fulfill()
        })
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testCollectionFetchError() {
        let expectation = self.expectationWithDescription("fetch collection")
        
        AMP.collection("gnarf") { collection in
            XCTFail()
            expectation.fulfill()
        }.onError { error in
            if case .CollectionNotFound(let name) = error {
                XCTAssertEqual(name, "gnarf")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
}

