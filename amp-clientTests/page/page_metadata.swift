import XCTest
@testable import ampclient

class pageMetadataTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMetadataFetchAsync() {
        let expectation = self.expectationWithDescription("fetch metadata")
        AMP.resetMemCache()
        
        AMP.collection("test").metadata("page_001") { metadata in
            XCTAssert(metadata.identifier == "page_001")
            XCTAssert(metadata.layout == "Layout 001")
            XCTAssertNil(metadata.parent)
            XCTAssertNil(metadata.title)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataFetchAsync2() {
        let expectation = self.expectationWithDescription("fetch metadata")
        AMP.resetMemCache()
        
        AMP.collection("test").metadata("page_002") { metadata in
                XCTAssert(metadata.identifier == "page_002")
                XCTAssert(metadata.layout == "Layout 002")
                XCTAssertNil(metadata.parent)
                XCTAssert(metadata.title == "Donec ullamcorper")
                expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataEnumerateAsync() {
        let expectation = self.expectationWithDescription("enumerate metadata")
       
        var count = 0
        AMP.collection("test").enumerateMetadata(nil) { metadata in
            XCTAssertNil(metadata.parent)
            count++
            if count == 2 {
                expectation.fulfill()
            }
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        XCTAssert(count == 2)
    }

    func testMetadataEnumerateAsync2() {
        let expectation = self.expectationWithDescription("enumerate metadata")
        
        AMP.collection("test").enumerateMetadata("page_002") { metadata in
            XCTAssert(metadata.parent == "page_002")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync() {
        let expectation = self.expectationWithDescription("enumerate metadata")
        
        AMP.collection("test").metadataList(nil) { list in
            XCTAssert(list.count == 2)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testMetadataListAsync2() {
        let expectation = self.expectationWithDescription("enumerate metadata")
        
        AMP.collection("test").metadataList("page_002") { list in
            XCTAssert(list.count == 1)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}
