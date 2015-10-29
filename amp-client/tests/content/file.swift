import XCTest
@testable import ampclient

class fileContentTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
       
    func testFileOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").fileData("File") { data in
            guard let outlet = AMP.collection("test").page("page_001").outlet("File"),
                  case let file as AMPFileContent = outlet else {
                    XCTFail("File outlet not found or of wrong type")
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