# ION Client

ION-Client for iOS and OS X clients

## Requirements:

- iOS 9.0+ / macOS 10.10+
- Xcode 9.4+
- Swift 4.1+

<!-- MarkdownTOC -->

1. [Setup](#setup)
    1. [Login to the API Server](#login-to-the-api-server)
2. [Getting collections](#getting-collections)
3. [Getting pages](#getting-pages)
    1. [Fetch a single page from a collection](#fetch-a-single-page-from-a-collection)
    2. [Fetch multiple pages from the same collection](#fetch-multiple-pages-from-the-same-collection)
    3. [Get child pages from a page](#get-child-pages-from-a-page)
    4. [Get meta data for a page without downloading the page](#get-meta-data-for-a-page-without-downloading-the-page)
4. [Getting outlets](#getting-outlets)
    1. [Fetch a single outlet](#fetch-a-single-outlet)
    2. [Fetch multiple outlets](#fetch-multiple-outlets)
    3. [Fetch all outlets](#fetch-all-outlets)
5. [Content types](#content-types)
    1. [Color](#color)
    2. [Container](#container)
    3. [DateTime](#datetime)
    4. [File](#file)
    5. [Flag](#flag)
    6. [Image](#image)
    7. [Media](#media)
    8. [Option](#option)
    9. [Text](#text)
6. [Error handling](#error-handling)
7. [Resetting caches](#resetting-caches)
    1. [Memory cache](#memory-cache)
    2. [Disk cache](#disk-cache)
    3. [Cache refresh](#cache-refresh)

<!-- /MarkdownTOC -->

# Setup

To use the ION client you'll need to supply some basic information:

- Base URL to the API server
- Locale to use

Example:

~~~swift
ION.config.serverURL = NSURL(string: "http://127.0.0.1:8000/client/v1/")
ION.config.locale = "en_US"
~~~

To be sure to produce no conflict with later ION calls put this in your AppDelegate.

Server URL and locale may be changed at any time afterwards, existing data is not deleted and stays cached.


## Login to the API Server

For logging in call the `login` function of the `ION` class **or** supply a `sessionToken` in the configuration when you decide to not use the login functionality of the ION server.

Example:

~~~swift
ION.login("testuser@example.com", password:"password") { success in
    print("login " + (success ? "suceeeded" : "failed"))
}
~~~

# Getting collections

All calls run through the ION class and it's class functions. Most calls have synchronous and asynchronous variants, the sync variants should only be used when you are sure the object is in the cache.

Async variant:

~~~swift
ION.collection("collection001") { result in
    guard case .Success(let collection) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }
    print("loaded collection \(collection.identifier)")
}
~~~

Sync variant:

~~~swift
let collection = ION.collection("collection001")
~~~

The sync variant fetches its values in the background async, so not all values will be available directly, **but** all appended calls to such an unfinished collection will be queued until it is available and called then.

**DO NOT** use for getting to a collection only, use the async variant for that, **USE** to queue calls!


# Getting pages

Fetching pages can be done in multiple ways.

## Fetch a single page from a collection

~~~swift
ION.collection("collection001").page("page001") { result in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("page \(page.identifier) loaded")
}
~~~

## Fetch multiple pages from the same collection

Variant 1:

~~~swift
ION.collection("collection001") { result in
    guard case .Success(let collection) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    collection.page("page001") { result in
        guard case .Success(let page) = result else {
          print("Error: ", result.error ?? .UnknownError)
        }

        print("page \(page.identifier) loaded")
    }
    collection.page("page002") { result in
        guard case .Success(let page) = result else {
          print("Error: ", result.error ?? .UnknownError)
        }

        print("page \(page.identifier) loaded")
    }
}
~~~

Variant 2:

~~~swift
let collection = ION.collection("collection001")
collection.page("page001") { result in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("page \(page.identifier) loaded")
}
collection.page("page002") { page in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("page \(page.identifier) loaded")
}
~~~

Be aware that no collection updates will be reflected if you cache a collection object this way.

## Get child pages from a page

~~~swift
ION.collection("collection001").page("page001").child("subpage001") { result in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("sub-page \(page.identifier) loaded")
}
~~~

## Get meta data for a page without downloading the page

~~~swift
ION.collection("collection001").metadata("page001") { result in
    guard case .Success(let metadata) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("page title \(metadata.title)")
    metadata.image { thumbnail in
        print("thumbnail size: \(image.size.width) x \(image.size.height)")
    }
}
~~~

# Getting outlets

This works analogous to pages but has some convenience functionality.

In a `page(identifier: String, callback:(IONPage -> Void))` callback block you may use the sync variants as the page you just fetched contains the content.

The result of an `outlet(*)` call is always an `IONContent` object. To get the values of the content object you'll need a switch:

~~~swift
switch(content) {
case let t as IONTextContent:
    print(t.plainText())

...

default:
    break
}
~~~

or at least a `if case let`:

~~~swift
if case let t as IONTextContent = content {
    print(t.plainText())
}
~~~


## Fetch a single outlet

~~~swift
ION.collection("collection001").page("page001").outlet("title") { result in
    guard case .Success(let content) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("outlet \(content.outlet) loaded")
}
~~~

## Fetch multiple outlets

Variant 1:

~~~swift
ION.collection("collection001").page("page001") { result in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    page.outlet("title") { result in
        guard case .Success(let outlet) = result else {
          print("Error: ", result.error ?? .UnknownError)
        }

        print("outlet \(content.outlet) loaded")
    }
    page.outlet("text") { result in
        guard case .Success(let content) = result else {
          print("Error: ", result.error ?? .UnknownError)
        }

        print("outlet \(content.outlet) loaded")
    }
}
~~~

Variant 2:

~~~swift
ION.collection("collection001").page("page001").outlet("title") { result in
    guard case .Success(let content) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("outlet \(content.outlet) loaded")
}.outlet("text") { result in
    guard case .Success(let content) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    print("outlet \(content.outlet) loaded")
}
~~~

## Fetch all outlets

~~~swift
ION.collection("collection001").page("page001") { result in
    guard case .Success(let page) = result else {
      print("Error: ", result.error ?? .UnknownError)
    }

    for content in page.content {
        print("outlet \(content.outlet) loaded")
    }
}
~~~

# Content types

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

All content types have the base class of `IONContentBase`. All content types extend the `IONPage` object with some convenience functions to make getting their values easier, following is a list with all available functions.


## Color

Content object:

- `color() -> XXColor`: Returns `UIColor` or `NSColor` instances of the object

Page extension:

- `cachedColor(name: String) -> XXColor`:
  Returns `UIColor` or `NSColor` instances of a color outlet if already cached
- `color(name: String, callback: (XXColor -> Void)) -> IONPage`:
  Calls callback with `UIColor` or `NSColor` instance, returns `self` for further chaining


## Container

Content object may be subscripted with an `Int` to get a child.

Page extension:

- `children(name: String) -> [IONContent]?`:
  Returns a list of children if the container was cached else `nil`
- `children(name: String, callback: ([IONContent] -> Void)) -> IONPage`:
  Calls callback with list of children (if there are some), returns `self` for further chaining


## DateTime

Content object has a `date` property that contains the parsed `NSDate`

Page extension:

- `date(name: String) -> NSDate?`:
  Returns a date if the value was cached already
- `date(name: String, callback: (Result<NSDate, IONError> -> Void)) -> IONPage`:
  Calls callback with `NSDate` object, returns `self` for further chaining


## File

Content object:

- `data(callback: (Result<NSData, IONError> -> Void))`:
  Returns memory mapped `NSData` for the content of the file, this initiates the file download if it is not in the cache
- `dataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (Result<CGImageRef, IONError> -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data

Page extension:

- `fileData(name: String, callback:(Result<NSData, IONError> -> Void)) -> IONPage`:
  Calls callback with `NSData` instance for the content of the file, returns `self` for further chaining


## Flag

Content object has a `enabled` property.

Page extension:

- `isSet(name: String) -> Bool?`:
  Returns if the flag is set when the value is cached already, else `nil`
- `isSet(name: String, callback: (Result<Bool, IONError> -> Void)) -> IONPage`:
  Calls callback with flag status, returns `self` for further chaining


## Image

Content object:

- `dataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (Result<CGImageRef, IONError> -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data

Page extension:

- `image(name: String, callback: (Result<XXImage, IONError> -> Void)) -> IONPage`:
  Calls callback with modified image (either `UIImage` or `NSImage`), returns `self` for further chaining
- `originalImage(name: String, callback: (Result<XXImage, IONError> -> Void)) -> IONPage`:
  Calls callback with original image (either `UIImage` or `NSImage`), returns `self` for further chaining


## Media

Content object:

- `data(callback: (Result<NSData, IONError> -> Void))`:
  Calls a callback with memory mapped `NSData` for the media file, **Warning**: this downloads the file!
- `dataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the modified image data
- `originalDataProvider(callback: (Result<CGDataProviderRef, IONError> -> Void))`
  Calls a callback with a `CGDataProvider` for the original image data
- `cgImage(original: Bool = false, callback: (Result<CGImageRef, IONError> -> Void))`
  Calls a callback with a `CGImage` for the image data
- `image(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the modified image data
- `originalImage(callback: (Result<XXImage, IONError> -> Void))`
  Calls a callback with a `UIImage` or `NSImage` for the original image data
- Use `url` property to get the URL of the file!


Page extension:

- `mediaURL(name: String) -> NSURL?`:
  Returns the URL to the media file if value was cached, else `nil`
- `mediaURL(name: String, callback: (Result<NSURL, IONError> -> Void)) -> IONPage`:
  Calls callback with the URL to the media file, returns `self` for further chaining
- `mediaData(name: String, callback: (Result<NSData, IONError> -> Void)) -> IONPage`:
  Calls callback with a `NSData` instance for the media file, **Warning**: this downloads the file! Returns `self` for further chaining


## Option

Content object has a `value` property.

Page extension:

- `selectedOption(name: String) -> String?`:
  Returns the selected option if cached, else `nil`
- `selectedOption(name: String, callback: (Result<String, IONError> -> Void)) -> IONPage`:
  Calls callback with selected option, returns `self` for further chaining


## Text

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
- `text(name: String, callback: (Result<String, IONError> -> Void)) -> IONPage`:
  Calls callback with plain text version, returns `self` for further chaining


# Error handling

All callbacks return a `Result<T, IONError>` enum.
There are two cases in that enum:

- `.Success(_ data: T)`
- `.Failure(_ error: IONError)`

so primarily you have to `guard` all accesses to the returned content:

```swift
guard case .Success(let content) = result else {
  print("Error: ", result.error ?? .UnknownError)
}

// use `content`
```

Here we assume the variable `result` is your input.


# Resetting caches

By default all caches are kept in sync with the server by calling a collection update all 10 minutes and invalidating stale objects after that call. The cache can only function correctly if you do not cache collection or page objects yourself. So best practice is always taking the `ION.collection("x").page("y") { // usage }` road. All calls that are processed that way are fully memory cached, so they should be both: fast and current.

## Memory cache

All accessed collections and pages will be kept in a memory cache to avoid constantly parsing their JSON representation from disk. Memory cache should be cleared on memory warnings as all objects in that cache may be easily reinstated after a purge with a small runtime penalty (disk access, JSON parsing)

Example:

~~~swift
ION.resetMemCache()
~~~

## Disk cache

Disk cache is kept per server and locale, so to wipe all disk caches you'll have to go through all locales and hosts you use. That cache contains JSON request responses and all downloaded media. Beware if the media files come from
another server than you send the api requests to they will be saved in a directory for that hostname, not in the API cache.

Example:

~~~swift
ION.resetDiskCache() // resets the cache for the current config
~~~

## Cache refresh

The first call to any collection after App-start will automatically cause a server-fetch.

You can set the cache timeout by setting `ION.config.cacheTimeout`, by default it is set to 600 seconds.

To force a collection update set `ION.config.lastOnlineUpdate` to `nil`.

