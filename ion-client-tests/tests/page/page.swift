//
//  page.swift
//  ion-client
//
//  Created by Johannes Schriewer on 28.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import XCTest
@testable import ion_client

class pageTests: LoggedInXCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    
    func testPageHashValue() {
        let expectation = self.expectationWithDescription("testPageHashValue")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(page.collection)
            XCTAssertEqual(page.hashValue, page.collection.hashValue + page.identifier.hashValue)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    

    func testPageFetchSync() {
        let expectation = self.expectationWithDescription("testPageFetchSync")
        ION.resetMemCache()
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPagePositionSync() {
        let expectation1 = self.expectationWithDescription("testPagePositionSync 1")
        let expectation2 = self.expectationWithDescription("testPagePositionSync 2")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation1.fulfill()
                return
            }

            let page = collection.page("page_001")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.position == 0)
            expectation1.fulfill()
        }

        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation2.fulfill()
                return
            }

            let page = collection.page("page_002")
            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "page_002")
            XCTAssert(page.position == 1)
            expectation2.fulfill()
        }

        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectationWithDescription("testPageFetchAsync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPagePositionAsync() {
        let expectation1 = self.expectationWithDescription("testPagePositionAync 1")
        let expectation2 = self.expectationWithDescription("testPagePositionAync 2")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation1.fulfill()
                return
            }

            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.position == 0)
            expectation1.fulfill()
        }
        
        ION.collection("test").page("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation2.fulfill()
                return
            }

            XCTAssert(page.identifier == "page_002")
            XCTAssert(page.position == 1)
            expectation2.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageFetchFail() {
        let expectation = self.expectationWithDescription("testPageFetchFail")
        
        ION.collection("test").page("unknown_page") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success = result else {
                if case .PageNotFound(let name) = result.error! {
                    XCTAssertEqual(name, "unknown_page")
                } else {
                    XCTFail()
                }
                expectation.fulfill()
                return
            }

            XCTFail()
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    func testPageParentAsync() {
        let expectation = self.expectationWithDescription("testPageParentAsync")
        
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageCount() {
        ION.collection("test").pageCount(nil) { count in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            XCTAssert(count == 2)
        }
        
        ION.collection("test").pageCount("page_002") { count in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            XCTAssert(count == 1)
        }
    }

    func testPageParent() {
        let expectation = self.expectationWithDescription("testPageParent")
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }

    func testPageChild() {
        let expectation = self.expectationWithDescription("testPageChild")
        
        ION.collection("test").page("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .Success(let child) = page.child("subpage_001") else {
                XCTFail("Child not found")
                expectation.fulfill()
                return
            }
            
            XCTAssert(child.identifier == "subpage_001")
            XCTAssert(child.parent == "page_002")
            print(child.layout)
            XCTAssert(child.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testPageInvalidChild() {
        let expectation = self.expectationWithDescription("testPageInvalidChild")
        
        ION.collection("test").page("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .Failure(let error) = page.child("invalid_page") else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case .PageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }

            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testPageInvalidChildAsync() {
        let expectation = self.expectationWithDescription("testPageInvalidChildAsync")
        
        ION.collection("test").page("page_002").child("invalid") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case .PageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
    
    func testPageChildInvalidParent() {
        let expectation = self.expectationWithDescription("testPageChildInvalidParent")
        
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .Failure(let error) = page.child("page_002") else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case .InvalidPageHierarchy = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    
    
    func testPageChildInvalidParentAsync() {
        let expectation = self.expectationWithDescription("testPageChildInvalidParentAsync")
        
        ION.collection("test").page("subpage_001").child("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case .InvalidPageHierarchy = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    

    func testPageChildAsync() {
        let expectation = self.expectationWithDescription("testPageChildAsync")
        
        ION.collection("test").page("page_002").child("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page)
            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testPageChildFail() {
        let expectation = self.expectationWithDescription("testPageChildFail")

        ION.collection("test").page("page_002").child("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success = result else {
                if case .InvalidPageHierarchy(let parent, let child) = result.error! {
                    XCTAssert(parent == "page_002")
                    XCTAssert(child == "page_001")
                } else {
                    XCTFail()
                }

                expectation.fulfill()
                return
            }

            XCTFail()
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }
    
//    func testPageEnumeration() {
//        let expectation = self.expectationWithDescription("testPageEnumeration")
//
//        var pageCount = 0;
//        ION.collection("test").pages { page in
//            XCTAssert(page.position == pageCount)
//            pageCount++
//            if (page.identifier != "page_001") && (page.identifier != "page_002") {
//                XCTFail()
//            }
//            if (pageCount == 2) {
//                expectation.fulfill()
//            }
//        }
//
//        self.waitForExpectationsWithTimeout(4.0, handler: nil)
//        XCTAssert(pageCount == 2)
//    }
    
    func testSubPageEnumeration() {
        let expectation = self.expectationWithDescription("testSubPageEnumeration")
        
        ION.collection("test").page("page_002").children { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testSubPageList() {
        let expectation = self.expectationWithDescription("testSubPageList")
        
        ION.collection("test").page("page_002").childrenList { list in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            XCTAssert(list.count == 1)
            if list.count == 1 {
                XCTAssert(list[0].identifier == "subpage_001")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(5.0, handler: nil)
    }

    func testOutletExists() {
        let expectation = self.expectationWithDescription("testOutletExists")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssert(page.outletExists("text").value == true)
            XCTAssert(page.outletExists("Unknown_Outlet").value == false)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testOutletExistsAsync() {
        let expectation = self.expectationWithDescription("testOutletExistsAsync")
        
        ION.collection("test").page("page_001").outletExists("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let exists) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertTrue(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testOutletDoesNotExistAsync() {
        let expectation = self.expectationWithDescription("testOutletDoesNotExistAsync")
        
        ION.collection("test").page("page_001").outletExists("Unknown_Outlet") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let exists) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertFalse(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    func testCancelablePage() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectationWithDescription("testCancelableCollection")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            // now this one collection is in the cache and no page
            XCTAssert(ION.collectionCache.count == 1)
            XCTAssert(collection.pageCache.count == 0)
            
            collection.page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(let page) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }

                // now we have one page
                XCTAssert(collection.pageCache.count == 1)
            
                // let's get a cancelable fork
                let p = page.cancelable()
                
                // now we have 2 pages in the cache
                XCTAssert(collection.pageCache.count == 2)
                
                // suspend the work queue to be able to queue deterministically
                dispatch_suspend(p.workQueue)
                
                // cancel the fork
                p.cancel()
                
                // on completion will now be called after cancelling
                p.onCompletion() { page, completed in
                    
                    // Test if the correct response queue is used
                    XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                    
                    XCTAssert(completed == false)
                    // cancel/finish has happened here already so only the original page should be in the cache
                    dispatch_async(p.workQueue) {
                        XCTAssert(collection.pageCache.count == 1)
                        expectation.fulfill()
                    }
                }
                
                // now start the thing
                dispatch_resume(p.workQueue)
            }
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    
    func testWaitUntilReady() {
        let expectation = self.expectationWithDescription("testWaitUntilReady")

        ION.collection("test").page("page_001").waitUntilReady{ page in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            XCTAssertNotNil(page)
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testNumberOfContentsForOutletSync() {
        let expectation = self.expectationWithDescription("testNumberOfContentsForOutletSync")
        
        ION.collection("test").page("page_001"){ result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page)
            XCTAssertEqual(page.numberOfContentsForOutlet("text").value, 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testNumberOfContentsForOutletAsync() {
        let expectation = self.expectationWithDescription("testNumberOfContentsForOutletAsync")
        
        ION.collection("test").page("page_001").numberOfContentsForOutlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let count) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(count)
            XCTAssertEqual(count, 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testFailOnInvalidPageIdentifier() {
        let expectation = self.expectationWithDescription("testFailOnInvalidPageIdentifier")
        
        ION.collection("test").page("invalidpageidentifier").outlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .DidFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(error.errorDomain, "com.anfema.ion")
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(2.0, handler: nil)
    }
    
    
    func testGetMetaPage() {
        let expectation = self.expectationWithDescription("testGetMetaPage")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let meta = page.metadata else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(meta.identifier, page.identifier)
            
            expectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testLoadCacheDB() {
        let expectation = self.expectationWithDescription("testLoadCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(_) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            // cache has content
            XCTAssertFalse((IONRequest.cacheDB ?? []).isEmpty)
            
            // set cacheDB to nil to force loading from file
            ION.resetDiskCache()
            ION.resetMemCache()
            IONRequest.cacheDB = nil
            
            // cache should now be empty
            XCTAssertTrue((IONRequest.cacheDB ?? []).isEmpty)
            
            ION.collection("test").page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(_) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                // cache should now be populated again
                XCTAssertNotNil(IONRequest.cacheDB)
                XCTAssertFalse(IONRequest.cacheDB!.isEmpty)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testLoadInvalidCacheDB() {
        let expectation = self.expectationWithDescription("testLoadInvalidCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(_) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            // cache has content
            XCTAssertFalse((IONRequest.cacheDB ?? []).isEmpty)
            
            // set cacheDB to nil to force loading from file
            ION.resetDiskCache()
            ION.resetMemCache()
            IONRequest.cacheDB = nil
            
            let locale = ION.config.locale
            let invalidJsonString = "invalid"
            let fileURL = self.cacheFile("cacheIndex.json", locale: locale)
            
            guard let file = fileURL.path else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard let basePath = self.cacheBaseDir(locale: locale).path else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            do {
                // make sure the cache dir is there
                if !NSFileManager.defaultManager().fileExistsAtPath(basePath) {
                    try NSFileManager.defaultManager().createDirectoryAtPath(basePath, withIntermediateDirectories: true, attributes: nil)
                }
                
                // try saving to disk
                try invalidJsonString.writeToFile(file, atomically: true, encoding: NSUTF8StringEncoding)
            } catch {
                // saving failed, remove disk cache completely because we don't have a clue what's in it
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(basePath)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
            }

            // cache should now be empty
            XCTAssertTrue((IONRequest.cacheDB ?? []).isEmpty)
            
            ION.collection("test").page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(_) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                // cache should now be populated again
                XCTAssertNotNil(IONRequest.cacheDB)
                XCTAssertFalse(IONRequest.cacheDB!.isEmpty)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    func testLoadMissingCacheDB() {
        let expectation = self.expectationWithDescription("testLoadMissingCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
            
            guard case .Success(_) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            // cache has content
            XCTAssertFalse((IONRequest.cacheDB ?? []).isEmpty)
            
            // set cacheDB to nil to force loading from file
            ION.resetDiskCache()
            ION.resetMemCache()
            IONRequest.cacheDB = nil
            
            let locale = ION.config.locale
            
            guard let basePath = self.cacheBaseDir(locale: locale).path else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(basePath)
            } catch {
                // ok nothing fatal could happen, do nothing
            }
            
            // cache should now be empty
            XCTAssertTrue((IONRequest.cacheDB ?? []).isEmpty)
            
            ION.collection("test").page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(ION.config.responseQueue))
                
                guard case .Success(_) = result else {
                    XCTFail()
                    expectation.fulfill()
                    return
                }
                
                // cache should now be populated again
                XCTAssertNotNil(IONRequest.cacheDB)
                XCTAssertFalse(IONRequest.cacheDB!.isEmpty)
                
                expectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(1.0, handler: nil)
    }
    
    
    
    /// Helper Functions
    private func cacheFile(filename: String, locale: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.ion/\(locale)/\(filename)")
        return fileURL
    }
    
    private func cacheBaseDir(locale locale: String) -> NSURL {
        let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)
        let fileURL = directoryURLs[0].URLByAppendingPathComponent("com.anfema.ion/\(locale)")
        return fileURL
    }
}
