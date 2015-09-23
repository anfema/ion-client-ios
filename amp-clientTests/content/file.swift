import XCTest
@testable import ampclient

class fileContentTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
        AMP.config.locale = "de_DE"
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
       
    func testFileOutletFetchAsync() {
        let expectation = self.expectationWithDescription("fetch outlet")
        
        AMP.collection("test").page("page_001").fileData("File") { data in
            guard let outlet = AMP.collection("test").page("page_001").outlet("File"),
                case .File(let file) = outlet else {
                    XCTFail("File outlet not found or of wrong type")
                    expectation.fulfill()
                    return
            }
            XCTAssert(file.checksumMethod == "sha256")
            XCTAssert(data.sha256().hexString() == file.checksum)
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(13.0, handler: nil)
    }
    
}