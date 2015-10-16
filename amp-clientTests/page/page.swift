import XCTest
@testable import ampclient

class pageTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testPageFetchSync() {
        let expectation = self.expectationWithDescription("fetch page")
        AMP.resetMemCache()
        
        AMP.collection("test") { collection in
            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            expectation.fulfill()
        }.onError() { error in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            XCTFail()
            expectation.fulfill()
        }.page("page_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchFail() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").onError() { error in
            if case .PageNotFound(let name) = error {
                XCTAssertEqual(name, "unknown_page")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }.page("unknown_page") { page in
            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageParentAsync() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("subpage_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageParent() {
        let page = AMP.collection("test").page("subpage_001")
        XCTAssertNotNil(page)
        XCTAssert(page.identifier == "subpage_001")
        XCTAssert(page.parent == "page_002")
    }

    func testPageChild() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("page_002").child("subpage_001") { page in
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageChildFail() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.config.errorHandler = { (collection, error) in
            if case .InvalidPageHierarchy(let parent, let child) = error {
                XCTAssert(parent == "page_002")
                XCTAssert(child == "page_001")
            } else {
                XCTFail()
            }
            expectation.fulfill()
        }
        
        AMP.collection("test").page("page_002").child("page_001") { page in
            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
        AMP.config.resetErrorHandler()
    }
    
    func testPageEnumeration() {
        let expectation = self.expectationWithDescription("fetch page")

        var pageCount = 0;
        AMP.collection("test").pages { page in
            pageCount++
            if (page.identifier != "page_001") && (page.identifier != "page_002") {
                XCTFail()
            }
            if pageCount == 2 {
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
        XCTAssert(pageCount == 2)
    }
    
    func testSubPageEnumeration() {
        let expectation = self.expectationWithDescription("fetch page")
        
        AMP.collection("test").page("page_002").children { page in
            XCTAssert(page.identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

}
