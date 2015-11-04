import XCTest
@testable import ampclient

class autoCacheTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCollectionFetchNoTimeout() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            AMP.collection("test") { collection2 in
                XCTAssert(collection.lastUpdate == collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testCollectionFetchWithTimeout() {
        let expectation = self.expectationWithDescription("fetch collection")
        AMP.config.cacheTimeout = 2
        AMP.config.lastOnlineUpdate = nil
        AMP.collection("test") { collection in
            XCTAssertNotNil(collection.lastUpdate)
            sleep(3)
            AMP.collection("test") { collection2 in
                XCTAssert(collection.lastUpdate != collection2.lastUpdate)
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
        AMP.config.cacheTimeout = 600
    }

    
}
