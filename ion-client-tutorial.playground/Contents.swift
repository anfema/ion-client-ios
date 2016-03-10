import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

import ion_client

ION.config.serverURL = NSURL(string: "https://bireise.anfema.com")
ION.config.responseQueue = dispatch_get_main_queue()
ION.config.locale = "de_DE"
ION.config.setBasicAuthCredentials(user: "bi-travel-app", password: "rxUxkLyw4K23N5Gh")

ION.collection("bi-travel-app") { result in
    
    guard case .Success(let collection) = result else {
        print(result.error!)
        return
    }
}