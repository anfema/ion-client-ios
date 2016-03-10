import Cocoa
import XCPlayground

XCPlaygroundPage.currentPage.needsIndefiniteExecution = true

//: [Previous (Installation)](@previous)
//: # Basic Setup
//: 
//: First of all you need to import the ion_client by adding `import ion_client`
//: to the top of your file in which you want to use the ion client.
import ion_client
//: Specify the url to the server you want to get the data from.
//:
//: > You can find the server urls of your accounts from [https://ionurl.com/developer](https://ionurl.com/developer).  
//: > But for now we can stick with this demo server:
ION.config.serverURL = NSURL(string: "https://ampdev2.anfema.com/client/v1/")
//: ## Optional:
//: Adjust the response queue that should be used for the callbacks.  
//: Usually using `dispatch_get_main_queue()` is the best choice, because interface updates
//: happen in the main queue. (default)  
//: But it's easy to use your own queue if you prefer:
ION.config.responseQueue = dispatch_queue_create("com.anfema.ion.ResponseQueue", DISPATCH_QUEUE_CONCURRENT)
//: That's it with the basic setup. We specified the server we want to get the data from
//: and defined the response queue for the callbacks.  
//: If the access to the contents is restricted - you can have look at the section [Authentification](@Authentification)
//: how to use the available authentication methods.
//:
//: [Next (Loading content)](@next)
