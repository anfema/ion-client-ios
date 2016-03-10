import Cocoa
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: [Previous (Installation)](@previous)
//: # Basic Setup
//: 
//: First of all you need to import the ion_client by adding `import ion_client`
//: to the top of your file in which you want to use the ion client.
import ion_client

ION.config.serverURL = NSURL(string: "https://ampdev2.anfema.com/client/v1/")
ION.config.responseQueue = dispatch_get_main_queue()
ION.config.setBasicAuthCredentials(user: "admin@anfe.ma", password: "test")

let collection = ION.collection("docs").waitUntilReady { result in
    print(result.optional()?.identifier)
}

let travels = collection.page("travels")

var images: [NSImage] = []

travels.childrenList { children in
    for child in children
    {
        child.identifier
        child.text("title") { result in
            print(result.optional())
        }
        
        child.image("thumbnail") { result in
            guard case .Success(let image) = result else {
                return
            }
            
            images.append(image)
        }
    }
}

//: [Next (Basic setup)](@next)
