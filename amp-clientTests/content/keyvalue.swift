import XCTest
@testable import ampclient

class keyValueContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testKVOutletFetchDictionarySync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let dict = page.keyValue("KeyValue") {
                XCTAssertNotNil(dict["foo"])
                XCTAssertNotNil(dict["wrzlpfrmpft"])
                XCTAssertNotNil(dict["glompf"])
            } else {
                XCTFail("kv content 'KeyValue' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testKVOutletFetchDictionaryAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").keyValue("KeyValue") { dict in
            XCTAssertNotNil(dict["foo"])
            XCTAssertNotNil(dict["wrzlpfrmpft"])
            XCTAssertNotNil(dict["glompf"])
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

    func testKVOutletFetchValueSync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001") { page in
            if let value = page.valueForKey("KeyValue", key: "foo") {
                XCTAssertEqual(value as? String, "bar")
            } else {
                XCTFail("kv content 'KeyValue' returned nil")
            }
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }
    
    func testKVOutletFetchValueAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").valueForKey("KeyValue", key: "foo") { value in
            XCTAssertEqual(value as? String, "bar")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(3.0, handler: nil)
    }

}