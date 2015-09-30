# AMP Client index

<!-- MarkdownTOC -->

- [AMP Client documentation](#amp-client-documentation)
  - [Setup](#setup)
  - [Login to the API Server](#login-to-the-api-server)
  - [Getting collections](#getting-collections)
  - [Getting pages](#getting-pages)
    - [Fetch a single page from a collection](#fetch-a-single-page-from-a-collection)
    - [Fetch multiple pages from the same collection](#fetch-multiple-pages-from-the-same-collection)
  - [Getting outlets](#getting-outlets)
    - [Fetch a single outlet](#fetch-a-single-outlet)
    - [Fetch multiple outlets](#fetch-multiple-outlets)
    - [Fetch all outlets](#fetch-all-outlets)
  - [Content types](#content-types)
    - [Color](#color)
    - [Container](#container)
    - [DateTime](#datetime)
    - [File](#file)
    - [Flag](#flag)
    - [Image](#image)
    - [KeyValue](#keyvalue)
    - [Media](#media)
    - [Option](#option)
    - [Text](#text)
  - [Error handling](#error-handling)
  - [Resetting caches](#resetting-caches)
    - [Memory cache](#memory-cache)
    - [Disk cache](#disk-cache)
    - [Cache refresh](#cache-refresh)

<!-- /MarkdownTOC -->


# AMP Client documentation

## Setup

To use the AMP client you'll need to supply some basic information:

- Base URL to the API server
- Locale to use

Example:

    AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
    AMP.config.locale = "en_US"

To be sure to produce no conflict with later AMP calls put this in your AppDelegate.

Server URL and locale may be changed at any time afterwards, existing data is not deleted and stays cached.


## Login to the API Server

For logging in call the `login` function of the `AMP` class or supply a `sessionToken` in the configuration when you decide to not use the login functionality of the AMP server.

Example:

    AMP.login("testuser@example.com", password:"password") { success in
        print("login " + (success ? "suceeeded" : "failed"))
    }


## Getting collections

All calls run through the AMP class and it's class functions. Most calls have synchronous and asynchronous variants, the sync variants should only be used when you are sure the object is in the cache.

Async variant:

    AMP.collection("collection001") { collection in
        print("loaded collection \(collection.identifier)")
    }

Sync variant:

    let collection = AMP.collection("collection001")

The sync variant fetches its values in the background async, so not all values will be available directly, **but** all appended calls to such an unfinished collection will be queued until it is available and called then.

**DO NOT** use for getting to a collection only, use the async variant for that, **USE** to queue calls!


## Getting pages

Fetching pages can be done in multiple ways.


### Fetch a single page from a collection

    AMP.collection("collection001").page("page001") { page in
        print("page \(page.identifier) loaded")
    }


### Fetch multiple pages from the same collection

Variant 1:

    AMP.collection("collection001") { collection in
        collection.page("page001") { page in
            print("page \(page.identifier) loaded")
        }
        collection.page("page002") { page in
            print("page \(page.identifier) loaded")
        }
    }

Variant 2:

    let collection = AMP.collection("collection001")
    collection.page("page001") { page in
        print("page \(page.identifier) loaded")
    }
    collection.page("page002") { page in
        print("page \(page.identifier) loaded")
    }


## Getting outlets

This works analogous to pages but has some convenience functionality.

The result of an `outlet(*)` call is always an `AMPContent` object that encapsulates the real content. To get the values of the content object you'll need a switch:

    switch(content) {
    case .Text(let t):
        print(t.plainText())
    
    ...
    
    default:
        break
    }

or at least a `if case`:

    if case .Text(let t) = content {
        print(t.plainText())
    }

or when you only need the `AMPContentBase` base class use the convenience function `getBaseObject()` on it:

    let obj = content.getBaseObject()
    print("outlet name \(obj.outlet)")


### Fetch a single outlet

    AMP.collection("collection001").page("page001").outlet("title") { content in
        print("outlet \(content.getBaseObject().outlet) loaded")
    }


### Fetch multiple outlets

Variant 1:

    AMP.collection("collection001").page("page001") { page in
        page.outlet("title") { content in
            print("outlet \(content.getBaseObject().outlet) loaded")
        }
        page.outlet("text") { content in
            print("outlet \(content.getBaseObject().outlet) loaded")
        }
    }


Variant 2:

    AMP.collection("collection001").page("page001").outlet("title") { content in
        print("outlet \(content.getBaseObject().outlet) loaded")
    }.outlet("text") { content in
        print("outlet \(content.getBaseObject().outlet) loaded")
    }


### Fetch all outlets

    AMP.collection("collection001").page("page001") { page in
        for content in page.content {
            print("outlet \(content.getBaseObject().outlet) loaded")
        }
    }


## Content types

The following content types are defined:

- Color
- Container
- DateTime
- File
- Flag
- Image
- KeyValue
- Media
- Option
- Text

All content types have the base class of `AMPContentBase` and are always encapsulated in the `AMPContent` enum. All content types extend the `AMPPage` object with some convenience functions to make getting their values easier,
following is a list with all available functions.


### Color

Content object:

- `color() -> XXColor`: Returns `UIColor` or `NSColor` instances of the object

Page extension:

- `cachedColor(name: String) -> XXColor`:
  Returns `UIColor` or `NSColor` instances of a color outlet if already cached
- `color(name: String, callback: (XXColor -> Void)) -> AMPPage`:
  Calls callback with `UIColor` or `NSColor` instance, returns `self` for further chaining


### Container

Content object may be subscripted with an `Int` to get a child.

Page extension:

- `children(name: String) -> [AMPContent]?`:
  Returns a list of children if the container was cached else `nil`
- `children(name: String, callback: ([AMPContent] -> Void)) -> AMPPage`:
  Calls callback with list of children (if there are some), returns `self` for further chaining


### DateTime

Content object has a `date` property that contains the parsed `NSDate`

Page extension:

- `date(name: String) -> NSDate?`:
  Returns a date if the value was cached already
- `date(name: String, callback: (NSDate -> Void)) -> AMPPage`:
  Calls callback with `NSDate` object, returns `self` for further chaining


### File

Content object:

- `data(callback: (NSData -> Void))`:
  Returns memory mapped `NSData` for the content of the file, this initiates the file download if it is not in the cache

Page extension:

- `fileData(name: String, callback:(NSData -> Void)) -> AMPPage`:
  Calls callback with `NSData` instance for the content of the file, returns `self` for further chaining


### Flag

Content object has a `enabled` property.

Page extension:

- `isSet(name: String) -> Bool?`:
  Returns if the flag is set when the value is cached already, else `nil`
- `isSet(name: String, callback: (Bool -> Void)) -> AMPPage`:
  Calls callback with flag status, returns `self` for further chaining


### Image

Content object:

- `dataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the image data
- `cgImage(callback: (CGImageRef -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the image data

Page extension:

- `image(name: String, callback: (XXImage -> Void)) -> AMPPage`:
  Calls callback with image (either `UIImage` or `NSImage`), returns `self` for further chaining


### KeyValue

Content object may be subscripted with a `String` key to get to the values

Page extension:

- `valueForKey(name: String, key: String) -> AnyObject?`:
  Returns the value for the key if data was cached, else `nil`
- `valueForKey(name: String, key:String, callback: (AnyObject -> Void)) -> AMPPage`:
  Calls callback with value, returns `self` for further chaining
- `keyValue(name: String) -> Dictionary<String, AnyObject>?`:
  Returns a dictionary if data was cached, else `nil`
- `keyValue(name: String, callback: (Dictionary<String, AnyObject> -> Void)) -> AMPPage`:
  Calls callback with dictionary, returns `self` for further chaining


### Media

Content object:

- `data(callback: (NSData -> Void))`:
  Calls a callback with memory mapped `NSData` for the media file, **Warning**: this downloads the file!
- Use `url` property to get the URL of the file!

Page extension:

- `mediaURL(name: String) -> NSURL?`:
  Returns the URL to the media file if value was cached, else `nil`
- `mediaURL(name: String, callback: (NSURL -> Void)) -> AMPPage`:
  Calls callback with the URL to the media file, returns `self` for further chaining
- `mediaData(name: String, callback: (NSData -> Void)) -> AMPPage`:
  Calls callback with a `NSData` instance for the media file, **Warning**: this downloads the file! Returns `self` for further chaining


### Option

Content object has a `value` property.

Page extension:

- `selectedOption(name: String) -> String?`:
  Returns the selected option if cached, else `nil`
- `selectedOption(name: String, callback: (String -> Void)) -> AMPPage`:
  Calls callback with selected option, returns `self` for further chaining


### Text

Content object:

- `htmlText() -> String?`:
  Returns html formatted text, see function docs for more info
- `attributedString() -> NSAttributedString?`:
  Returns `NSAttributedString` formatted text, see function docs for more info
- `plainText() -> String?`:
  Returns plain text string, see function docs for more info

Page extension:

- `text(name: String) -> String?`:
  Returns the plain text version if cached, else `nil`
- `text(name: String, callback: (String -> Void)) -> AMPPage`:
  Calls callback with plain text version, returns `self` for further chaining


## Error handling

`AMPCollection` as well as `AMPPage` have `onError(callback: (ErrorType -> Void))`-Handlers that may be chained like
the `page` or `outlet` calls are. They will be called if something goes wrong immediately. The 'success' block will
not be called in such a situation to avoid error handling code in such blocks.

Example:

    AMP.collection("collection001").onError() { error in
        print("collection failed to load: \(error)")
    }.page("page001") { page in
        print("page \(page.identifier) loaded")
    }.onError() { error in
        print("page failed to load: \(error)")
    }


## Resetting caches

Cache resets are currently completely manual, in future automatic cache invalidation will be handled on collection, page and content level.


### Memory cache

All accessed collections and pages will be kept in a memory cache to avoid constantly parsing their JSON representation from disk. Memory cache should be cleared on memory warnings as all objects in that cache may be easily reinstated after a purge with a small runtime penalty (disk access, JSON parsing)

Example:

    AMP.resetMemCache()


### Disk cache

Disk cache is kept per server and locale, so to wipe all disk caches you'll have to go through all locales and hosts you use. That cache contains JSON request responses and all downloaded media. Beware if the media files come from
another server than you send the api requests to they will be saved in a directory for that hostname, not in the API cache.

Example:

    AMP.resetDiskCache()                                    // resets the cache for the current config
    AMP.resetDiskCache(host: "example.com", locale:"de_DE") // resets the cache for example.com and `de_DE` locale


### Cache refresh

Cache refresh will refresh only those collections and pages that are currently cached in memory because the caching system currently does not know what is exactly in the cache. (This will be fixed in the future)

Example:

    // refresh all loaded collections
    AMP.refreshCache() { collection in
        print("collection refreshed: \(collection.identifier)")
    }

    // refresh all loaded pages in collection "collection001"
    AMP.refreshCache(collection: "collection001") { page in
        print("page refreshed: \(page.identifier)")
    }

    // refresh page "page001" in collection "collection001"
    AMP.refreshCache(collection: "collection001", page: "page001") { refreshed, page in
        if refreshed {
            print("page refreshed: \(page.identifier)")
        } else {
            print("page up to date: \(page.identifier)")
        }
    }

