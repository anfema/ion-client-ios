import XCTest
@testable import ampclient

class collectionTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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

