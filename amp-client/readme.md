# AMP Client index

<!-- MarkdownTOC -->

1. [AMP Client documentation](#amp-client-documentation)
    1. [Setup](#setup)
    2. [Login to the API Server](#login-to-the-api-server)
    3. [Getting collections](#getting-collections)
    4. [Getting pages](#getting-pages)
        1. [Fetch a single page from a collection](#fetch-a-single-page-from-a-collection)
        2. [Fetch multiple pages from the same collection](#fetch-multiple-pages-from-the-same-collection)
        3. [Get child pages from a page](#get-child-pages-from-a-page)
        4. [Get meta data for a page without downloading the page](#get-meta-data-for-a-page-without-downloading-the-page)
    5. [Getting outlets](#getting-outlets)
        1. [Fetch a single outlet](#fetch-a-single-outlet)
        2. [Fetch multiple outlets](#fetch-multiple-outlets)
        3. [Fetch all outlets](#fetch-all-outlets)
    6. [Content types](#content-types)
        1. [Color](#color)
        2. [Container](#container)
        3. [DateTime](#datetime)
        4. [File](#file)
        5. [Flag](#flag)
        6. [Image](#image)
        7. [Media](#media)
        8. [Option](#option)
        9. [Text](#text)
    7. [Error handling](#error-handling)
    8. [Resetting caches](#resetting-caches)
        1. [Memory cache](#memory-cache)
        2. [Disk cache](#disk-cache)
        3. [Cache refresh](#cache-refresh)

<!-- /MarkdownTOC -->


# AMP Client documentation

## Setup

To use the AMP client you'll need to supply some basic information:

- Base URL to the API server
- Locale to use

Example:

~~~swift
AMP.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
AMP.config.locale = "en_US"
~~~

To be sure to produce no conflict with later AMP calls put this in your AppDelegate.

Server URL and locale may be changed at any time afterwards, existing data is not deleted and stays cached.


## Login to the API Server

For logging in call the `login` function of the `AMP` class **or** supply a `sessionToken` in the configuration when you decide to not use the login functionality of the AMP server.

Example:

~~~swift
AMP.login("testuser@example.com", password:"password") { success in
    print("login " + (success ? "suceeeded" : "failed"))
}
~~~

## Getting collections

All calls run through the AMP class and it's class functions. Most calls have synchronous and asynchronous variants, the sync variants should only be used when you are sure the object is in the cache.

When you request a collection that is not found on the server no queued commands or success blocks will be called, just the error blocks, see [Error handling](#error-handling) for more information.

Async variant:

~~~swift
AMP.collection("collection001") { collection in
    print("loaded collection \(collection.identifier)")
}
~~~

Sync variant:

~~~swift
let collection = AMP.collection("collection001")
~~~

The sync variant fetches its values in the background async, so not all values will be available directly, **but** all appended calls to such an unfinished collection will be queued until it is available and called then.

**DO NOT** use for getting to a collection only, use the async variant for that, **USE** to queue calls!


## Getting pages

When you request a page that is not found in the collection no queued commands or success blocks will be called, just the error blocks, see [Error handling](#error-handling) for more information.

Fetching pages can be done in multiple ways.


### Fetch a single page from a collection

~~~swift
AMP.collection("collection001").page("page001") { page in
    print("page \(page.identifier) loaded")
}
~~~

### Fetch multiple pages from the same collection

Variant 1:

~~~swift
AMP.collection("collection001") { collection in
    collection.page("page001") { page in
        print("page \(page.identifier) loaded")
    }
    collection.page("page002") { page in
        print("page \(page.identifier) loaded")
    }
}
~~~

Variant 2:

~~~swift
let collection = AMP.collection("collection001")
collection.page("page001") { page in
    print("page \(page.identifier) loaded")
}
collection.page("page002") { page in
    print("page \(page.identifier) loaded")
}
~~~

### Get child pages from a page

~~~swift
AMP.collection("collection001").page("page001").child("subpage001") { page in
    print("sub-page \(page.identifier) loaded")
}
~~~

### Get meta data for a page without downloading the page

~~~swift
AMP.collection("collection001").metadata("page001") { metadata in
    print("page title \(metadata.title)")
    metadata.image { thumbnail in
        print("thumbnail size: \(image.size.width) x \(image.size.height)")
    }
}
~~~

## Getting outlets

This works analogous to pages but has some convenience functionality.

In a `page(identifier: String, callback:(AMPPage -> Void))` callback block you may use the sync variants as the page you just fetched contains the content.

When you request an outlet that is not found in the page no queued commands or success blocks will be called, just the error blocks of the page will be called, see [Error handling](#error-handling) for more information.

The result of an `outlet(*)` call is always an `AMPContent` object. To get the values of the content object you'll need a switch:

~~~swift
switch(content) {
case let t as AMPTextContent:
    print(t.plainText())

...

default:
    break
}
~~~

or at least a `if case let`:

~~~swift
if case let t as AMPTextContent = content {
    print(t.plainText())
}
~~~


### Fetch a single outlet

~~~swift
AMP.collection("collection001").page("page001").outlet("title") { content in
    print("outlet \(content.getBaseObject().outlet) loaded")
}
~~~

### Fetch multiple outlets

Variant 1:

~~~swift
AMP.collection("collection001").page("page001") { page in
    page.outlet("title") { content in
        print("outlet \(content.outlet) loaded")
    }
    page.outlet("text") { content in
        print("outlet \(content.outlet) loaded")
    }
}
~~~

Variant 2:

~~~swift
AMP.collection("collection001").page("page001").outlet("title") { content in
    print("outlet \(content.outlet) loaded")
}.outlet("text") { content in
    print("outlet \(content.outlet) loaded")
}
~~~

### Fetch all outlets

~~~swift
AMP.collection("collection001").page("page001") { page in
    for content in page.content {
        print("outlet \(content.outlet) loaded")
    }
}
~~~

## Content types

The following content types are defined:

- Color
- Container
- DateTime
- File
- Flag
- Image
- Media
- Option
- Text

All content types have the base class of `AMPContentBase`. All content types extend the `AMPPage` object with some convenience functions to make getting their values easier, following is a list with all available functions.


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
- `dataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (CGImageRef -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data

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
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (CGImageRef -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data

Page extension:

- `image(name: String, callback: (XXImage -> Void)) -> AMPPage`:
  Calls callback with modified image (either `UIImage` or `NSImage`), returns `self` for further chaining
- `originalImage(name: String, callback: (XXImage -> Void)) -> AMPPage`:
  Calls callback with original image (either `UIImage` or `NSImage`), returns `self` for further chaining


### Media

Content object:

- `data(callback: (NSData -> Void))`:
  Calls a callback with memory mapped `NSData` for the media file, **Warning**: this downloads the file!
- `dataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (CGDataProviderRef -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (CGImageRef -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (XXImage -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data
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

`AMPCollection` as well as `AMPPage` have `onError(callback: (ErrorType -> Void))`-Handlers that may be chained like the `page` or `outlet` calls are. They will be called if something goes wrong immediately. The 'success' block will
not be called in such a situation to avoid error handling code in such blocks.

The error handling block has to appear before calls that should be caught in it. If no error handling block is defined the error bubbles up.

There is a global error handler in `AMP.config.errorHandler` that catches all errors that did bubble up and were not caught. The default implementation just logs `AMP unhandled error: \(error)`. The default handler can be restored by calling `AMP.config.resetErrorHandler()`.

Example:

~~~swift
AMP.config.errorHandler = { (collection, error) in
    print("collection failed to load: \(error)")
}

AMP.collection("collection001").onError() { error in
    print("page failed to load: \(error)")
}.page("page001") { page in
    print("page \(page.identifier) loaded")
}
~~~

## Resetting caches

Cache resets are currently completely manual, in future automatic cache invalidation will be handled on collection, page and content level.


### Memory cache

All accessed collections and pages will be kept in a memory cache to avoid constantly parsing their JSON representation from disk. Memory cache should be cleared on memory warnings as all objects in that cache may be easily reinstated after a purge with a small runtime penalty (disk access, JSON parsing)

Example:

~~~swift
AMP.resetMemCache()
~~~

### Disk cache

Disk cache is kept per server and locale, so to wipe all disk caches you'll have to go through all locales and hosts you use. That cache contains JSON request responses and all downloaded media. Beware if the media files come from
another server than you send the api requests to they will be saved in a directory for that hostname, not in the API cache.

Example:

~~~swift
AMP.resetDiskCache() // resets the cache for the current config
~~~

### Cache refresh

The first call to any collection after App-start will automatically cause a server-fetch.

You can set the cache timeout by setting `AMP.config.cacheTimeout`, by default it is set to 600 seconds.

To force a collection update set `AMP.config.lastOnlineUpdate` to `nil`.

