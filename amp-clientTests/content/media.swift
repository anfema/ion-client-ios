import XCTest
@testable import ampclient

class mediaContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testFileOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").mediaData("Media") { data in
            guard let outlet = AMP.collection("test").page("page_001").outlet("Media"),
                  case let file as AMPMediaContent = outlet else {
                    XCTFail("Media outlet not found or of wrong type")
                    expectation.fulfill()
                    return
            }
            XCTAssert(file.checksumMethod == "sha256")
            XCTAssert(data.cryptoHash(HashTypes(rawValue: file.checksumMethod)!).hexString() == file.checksum)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
}