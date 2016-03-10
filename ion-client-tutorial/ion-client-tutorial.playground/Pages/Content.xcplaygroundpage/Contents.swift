import Cocoa
import XCPlayground
import ion_client
XCPlaygroundPage.currentPage.needsIndefiniteExecution = true
ION.config.serverURL = NSURL(string: "https://ampdev2.anfema.com/client/v1/")
ION.config.setBasicAuthCredentials(user: "admin@anfe.ma", password: "test")

//: [Previous (Basic setup)](@previous)
//: # Loading content
//:
//: So! Let the fun begin!  
//: The setup of ION is pretty boring. But now let's talk about about the interesting bits: *The content.*  
//: Content is king. No matter what plattform you are supporting or what type of application you want to
//: build - without content the whole project is worth nothing.  
//:
//: Because we know that good and of course good looking content is very important, we want to reduce your
//: effort to get content into your app, so you can spend more time in making your app look awesome!
//:
//: # Collection
//: 
//: The basic element for getting content is the *collection*.  
//: A collection is basically a container for all your content.  
//: Usually you only have one collection per app.
//: But of course you can use multiple collections at once.

//: Obtaining a collection is very easy. Just type ION.collection and add the collection identifier
//: as the parameter of the function:
let collection = ION.collection("collection") { result in
    guard case .Success(let collection) = result else {
        print("Oh no! An error occurred! \(result.error!)")
        return
    }
    
    print("Everything went fine! Collection loaded! \(collection)")
}
//: Hmmm. It seems that an error occurred, saying `CollectionNotFound`.  
//: I guess it's my fault - because I used the wrong collection identifier.  
//: Let's try again with `docs` as collection identifier:
let docsCollection = ION.collection("docs") { result in
    guard case .Success(let collection) = result else {
        print("Oh no! An error occurred! \(result.error!)")
        return
    }
    
    print("Everything went fine! Collection loaded! \(collection)")
}
//: Ha! Perfect. This looks much better. Now the correct collection was loaded and is ready to use.
//:
//: But I have to admit... I fooled you intentionally.  
//: I just wanted to show you, that you always have the option to handle errors without much overhead.
//: Handling your errors is good. So don't hesitate and make use of it. Your users will thank you
//: when they know what is going on.

//: # Page
//: 
//: Previously said, collections are containers only. Usually one container for one app.
//: Pages are nested inside of collections and are used to specify the content for a specific layout.
//: In iOS language:

//:
//: [Next (Outlets)](@next)
