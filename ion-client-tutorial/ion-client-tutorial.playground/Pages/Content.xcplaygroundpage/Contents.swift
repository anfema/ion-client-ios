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
//: ---
//: The content you will get from ION consists of three elements:  
//: [Collections](Collection), [Pages](Page) and [Outlets](Outlet)
//:
//: The Collection is the basic "root" element, which typically exists only once per app.
//: (You can have of course more if you want)
//: The collection handles the requests made to the backend, the caching and the loading of all contained
//: Pages and their Outlets.
//:
//: The Page items in the collection are used to define the structure of the app. Pages can also be nested to
//: represent more complex hierarchies.
//:
//: The Outlet items are the leafes in the structure and contain the content.
//:
//: ---
//: Lets have a look at the structure of our little example:
//: One collection with the identifier "docs". Nested in that collection are three pages: "animals", "news",
//: and "articles".
//: * Collection (identifier: docs)
//:     * Page (identifier: animals)
//:         * Page (identifier: normal-cat)
//:         * Page (identifier: fluffy-cat)
//:     * Page (identifier: news)
//:     * Page (identifier: articles)
//:         * Page (identifier: sad-cat.story)
//:             * Outlet (identifier: title)
//:             * Outlet (identifier: date)
//:             * Outlet (identifier: subtitle)
//:             * Outlet (identifier: image)
//:             * Outlet (identifier: story)
//:         * Page (identifier: funny-cat-story)
//:             * Outlet (identifier: title)
//:             * Outlet (identifier: date)
//:             * Outlet (identifier: subtitle)
//:             * Outlet (identifier: image)
//:             * Outlet (identifier: story)
//: 



//: # Collection
//: 
//: The basic element for getting content is the *collection*.  
//: A collection is basically a container for all your content.  
//: Usually you only have one collection per app.
//: But of course you can use multiple collections at once.

//: Obtaining a collection is very easy. Just call the class function `collection` on `ION` and add the collection
//: identifier as parameter:
ION.collection("collection") { result in
    guard case .Success(let collection) = result else {
        print("Oh no! An error occurred! \(result.error!)")
        return
    }
    
    print("Everything went fine! Collection loaded! \(collection)")
}
//: Hmmm. It seems that an error occurred, saying `CollectionNotFound`.  
//: I guess it's my fault - because I used the wrong collection identifier.  
//: Let's try again with `docs` as collection identifier:
ION.collection("docs") { result in
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
ION.collection("docs").page("animals") { result in
    guard case .Success(let animals) = result else {
        print("no animals found! \(result.error!)")
        return
    }
    
    animals.children({ result in
        guard case .Success(let animal) = result else {
            return
        }
        
        let type = animal.text("type").optional() ?? "unknown animal"
        let isFluffy = animal.isSet("is-fluffy").optional() ?? false
        
        if isFluffy {
            print("\(type) is fluffy!")
        } else {
            print("\(type) is not fluffy!")
        }
    })
}


//:
//: [Next (Outlets)](@next)
