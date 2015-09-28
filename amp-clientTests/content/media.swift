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
                  case .Media(let file) = outlet else {
                    XCTFail("Media outlet not found or of wrong type")
                    expectation.fulfill()
                    return
            }
            XCTAssert(file.checksumMethod == "sha256")
            XCTAssert(data.cryptoHash(HashTypes(rawValue: file.checksumMethod)!).hexString() == file.checksum)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(13.0, handler: nil)
    }
}