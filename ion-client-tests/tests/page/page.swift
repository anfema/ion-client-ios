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
        let expectation = self.expectation(description: "testPageHashValue")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(page.collection)
            XCTAssertEqual(page.hashValue, page.collection.hashValue + page.identifier.hashValue)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    

    func testPageFetchSync() {
        let expectation = self.expectation(description: "testPageFetchSync")
        ION.resetMemCache()
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPagePositionSync() {
        let expectation1 = self.expectation(description: "testPagePositionSync 1")
        let expectation2 = self.expectation(description: "testPagePositionSync 2")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
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
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
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

        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPageFetchAsync() {
        let expectation = self.expectation(description: "testPageFetchAsync")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "page_001")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPagePositionAsync() {
        let expectation1 = self.expectation(description: "testPagePositionAync 1")
        let expectation2 = self.expectation(description: "testPagePositionAync 2")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
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
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation2.fulfill()
                return
            }

            XCTAssert(page.identifier == "page_002")
            XCTAssert(page.position == 1)
            expectation2.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPageFetchFail() {
        let expectation = self.expectation(description: "testPageFetchFail")
        
        ION.collection("test").page("unknown_page") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.pageNotFound(let name) = result.error! {
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
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testPageParentAsync() {
        let expectation = self.expectation(description: "testPageParentAsync")
        
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testPageCount() {
        ION.collection("test").pageCount(nil) { count in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssert(count == 2)
        }
        
        ION.collection("test").pageCount("page_002") { count in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssert(count == 1)
        }
    }

    func testPageParent() {
        let expectation = self.expectation(description: "testPageParent")
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            XCTAssert(page.parent == "page_002")
            XCTAssert(page.layout == "layout-001")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }

    func testPageChild() {
        let expectation = self.expectation(description: "testPageChild")
        
        ION.collection("test").page("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .success(let child) = page.child("subpage_001") else {
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testPageInvalidChild() {
        let expectation = self.expectation(description: "testPageInvalidChild")
        
        ION.collection("test").page("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            guard case .failure(let error) = page.child("invalid_page") else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case IONError.pageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }

            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testPageInvalidChildAsync() {
        let expectation = self.expectation(description: "testPageInvalidChildAsync")
        
        ION.collection("test").page("page_002").child("invalid") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case IONError.pageNotFound = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    
    
    func testPageChildInvalidParent() {
        let expectation = self.expectation(description: "testPageChildInvalidParent")
        
        ION.collection("test").page("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case .failure(let error) = page.child("page_002") else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case IONError.invalidPageHierarchy = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    
    
    func testPageChildInvalidParentAsync() {
        let expectation = self.expectation(description: "testPageChildInvalidParentAsync")
        
        ION.collection("test").page("subpage_001").child("page_002") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail("Child found")
                expectation.fulfill()
                return
            }
            
            guard case IONError.invalidPageHierarchy = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }
    

    func testPageChildAsync() {
        let expectation = self.expectation(description: "testPageChildAsync")
        
        ION.collection("test").page("page_002").child("subpage_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testPageChildFail() {
        let expectation = self.expectation(description: "testPageChildFail")

        ION.collection("test").page("page_002").child("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success = result else {
                if case IONError.invalidPageHierarchy(let parent, let child) = result.error! {
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
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
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
        let expectation = self.expectation(description: "testSubPageEnumeration")
        
        ION.collection("test").page("page_002").children { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssert(page.identifier == "subpage_001")
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testSubPageList() {
        let expectation = self.expectation(description: "testSubPageList")
        
        ION.collection("test").page("page_002").childrenList { list in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssert(list.count == 1)
            if list.count == 1 {
                XCTAssert(list[0].identifier == "subpage_001")
            }
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 5.0, handler: nil)
    }

    func testOutletExists() {
        let expectation = self.expectation(description: "testOutletExists")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            XCTAssert(page.outletExists("text").value == true)
            XCTAssert(page.outletExists("Unknown_Outlet").value == false)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testOutletExistsAsync() {
        let expectation = self.expectation(description: "testOutletExistsAsync")
        
        ION.collection("test").page("page_001").outletExists("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let exists) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertTrue(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testOutletDoesNotExistAsync() {
        let expectation = self.expectation(description: "testOutletDoesNotExistAsync")
        
        ION.collection("test").page("page_001").outletExists("Unknown_Outlet") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let exists) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertFalse(exists)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    func testCancelablePage() {
        ION.resetMemCache()
        XCTAssert(ION.collectionCache.count == 0)
        
        let expectation = self.expectation(description: "testCancelableCollection")
        
        ION.collection("test") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let collection) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            // now this one collection is in the cache and no page
            XCTAssert(ION.collectionCache.count == 1)
            XCTAssert(collection.pageCache.count == 0)
            
            collection.page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(let page) = result else {
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
                p.workQueue.suspend()
                
                // cancel the fork
                p.cancel()
                
                // on completion will now be called after cancelling
                p.onCompletion() { page, completed in
                    
                    // Test if the correct response queue is used
                    XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                    
                    XCTAssert(completed == false)
                    // cancel/finish has happened here already so only the original page should be in the cache
                    p.workQueue.async {
                        XCTAssert(collection.pageCache.count == 1)
                        expectation.fulfill()
                    }
                }
                
                // now start the thing
                p.workQueue.resume()
            }
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }

    
    func testWaitUntilReady() {
        let expectation = self.expectation(description: "testWaitUntilReady")

        ION.collection("test").page("page_001").waitUntilReady{ page in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            XCTAssertNotNil(page)
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testNumberOfContentsForOutletSync() {
        let expectation = self.expectation(description: "testNumberOfContentsForOutletSync")
        
        ION.collection("test").page("page_001"){ result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }

            XCTAssertNotNil(page)
            XCTAssertEqual(page.numberOfContentsForOutlet("text").value, 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testNumberOfContentsForOutletAsync() {
        let expectation = self.expectation(description: "testNumberOfContentsForOutletAsync")
        
        ION.collection("test").page("page_001").numberOfContentsForOutlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let count) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertNotNil(count)
            XCTAssertEqual(count, 1)
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testFailOnInvalidPageIdentifier() {
        let expectation = self.expectation(description: "testFailOnInvalidPageIdentifier")
        
        ION.collection("test").page("invalidpageidentifier").outlet("text") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .failure(let error) = result else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            guard case IONError.didFail = error else {
                XCTFail()
                expectation.fulfill()
                return
            }
            
            XCTAssertEqual(IONError.didFail.errorDomain, "com.anfema.ion")
            
            expectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 2.0, handler: nil)
    }
    
    
    func testGetMetaPage() {
        let expectation = self.expectation(description: "testGetMetaPage")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(let page) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testLoadCacheDB() {
        let expectation = self.expectation(description: "testLoadCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(_) = result else {
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
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(_) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testLoadInvalidCacheDB() {
        let expectation = self.expectation(description: "testLoadInvalidCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(_) = result else {
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
            
            let file = fileURL.path
            let basePath = self.cacheBaseDir(locale: locale).path
            
            do {
                // make sure the cache dir is there
                if !FileManager.default.fileExists(atPath: basePath) {
                    try FileManager.default.createDirectory(atPath: basePath, withIntermediateDirectories: true, attributes: nil)
                }
                
                // try saving to disk
                try invalidJsonString.write(toFile: file, atomically: true, encoding: String.Encoding.utf8)
            } catch {
                // saving failed, remove disk cache completely because we don't have a clue what's in it
                do {
                    try FileManager.default.removeItem(atPath: basePath)
                } catch {
                    // ok nothing fatal could happen, do nothing
                }
            }

            // cache should now be empty
            XCTAssertTrue((IONRequest.cacheDB ?? []).isEmpty)
            
            ION.collection("test").page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(_) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    func testLoadMissingCacheDB() {
        let expectation = self.expectation(description: "testLoadMissingCacheDB")
        
        ION.collection("test").page("page_001") { result in
            
            // Test if the correct response queue is used
            XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
            
            guard case .success(_) = result else {
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
            let basePath = self.cacheBaseDir(locale: locale).path
            
            do {
                try FileManager.default.removeItem(atPath: basePath)
            } catch {
                // ok nothing fatal could happen, do nothing
            }
            
            // cache should now be empty
            XCTAssertTrue((IONRequest.cacheDB ?? []).isEmpty)
            
            ION.collection("test").page("page_001") { result in
                
                // Test if the correct response queue is used
                XCTAssertTrue(currentQueueLabel == ION.config.responseQueue.label)
                
                guard case .success(_) = result else {
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
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    
    
    /// Helper Functions
    fileprivate func cacheFile(_ filename: String, locale: String) -> URL {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = directoryURLs[0].appendingPathComponent("com.anfema.ion/\(locale)/\(filename)")
        return fileURL
    }
    
    fileprivate func cacheBaseDir(locale: String) -> URL {
        let directoryURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        let fileURL = directoryURLs[0].appendingPathComponent("com.anfema.ion/\(locale)")
        return fileURL
    }
}
