//
//  content.swift
//  ion-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation
import UIKit.UIImage
import UIKit.UIColor

/// Container content, contains other content objects
open class IONContainerContent: IONContent {

    /// Children of this container
    open var children: [IONContent]


    /// Initialize container content object from JSON
    /// Container content children can be accessed by subscripting the container content object
    ///
    /// - parameter json: `JSONObject` that contains the serialized container content object
    ///
    /// - throws: `IONError.jsonObjectExpected` when `json` is no `JSONDictionary`
    ///           `IONError.jsonArrayExpected` when `json["children"]` is no `JSONArray`
    ///
    override init(json: JSONObject) throws {
        guard case .jsonDictionary(let dict) = json else {
            throw IONError.jsonObjectExpected(json)
        }

        guard let rawChildren = dict["children"],
            case .jsonArray(let children) = rawChildren else {
                throw IONError.jsonArrayExpected(json)
        }

        self.children = []
        for child in children {
            do {
                try self.children.append(IONContent.factory(json: child))
            } catch {
                if ION.config.loggingEnabled {
                    print("ION: Deserialization failed")
                }
            }
        }

        try super.init(json: json)
    }


    /// Container content has a subscript for it's children
    subscript(index: Int) -> IONContent? {
        guard index > -1 && index < self.children.count else {
            return nil
        }

        return self.children[index]
    }
}


/// Container extension to IONPage
extension IONPage {

    /// Fetch `IONContent`-Array for named outlet
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - returns: `Result.Success` containing an array of `IONContent` objects if the outlet is a container outlet
    ///            and the page was already cached, else an `Result.Failure` containing an `IONError`.
    func children(_ name: String, atPosition position: Int = 0) -> Result<[IONContent], Error> {
        let result = self.outlet(name, atPosition: position)

        guard case .success(let content) = result else {
            return .failure(result.error ?? IONError.unknownError)
        }

        if case let content as IONContainerContent = content {
            return .success(content.children)
        }

        return .failure(IONError.outletIncompatible)
    }


    /// Fetch `IONContent`-Array for named outlet asynchronously
    ///
    /// - parameter name: The name of the outlet
    /// - parameter position: Position in the array (optional)
    /// - parameter callback: Block to call when the container outlet becomes available.
    ///                       Provides `Result.Success` containing an array of `IONContent` objects when successful, or
    ///                       `Result.Failure` containing an `IONError` when an error occurred.
    /// - returns: self for chaining
    @discardableResult func children(_ name: String, atPosition position: Int = 0, callback: @escaping ((Result<[IONContent], Error>) -> Void)) -> IONPage {
        workQueue.async {
            responseQueueCallback(callback, parameter: self.children(name, atPosition: position))
        }

        return self
    }
}


public extension Content {

    /// Provides a container content for a specific outlet identifier taking an optional position into account
    /// - parameter identifier: The identifier of the outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    ///
    /// __Warning:__ The page has to be full loaded before one can access content
    func containerContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONContainerContent? {
        return self.content(identifier, at: position)
    }


    func containerContents(_ identifier: OutletIdentifier) -> [IONContainerContent]? {
        let contents = self.all.filter({$0.outlet == identifier}).sorted(by: {$0.position < $1.position})
        return contents.isEmpty ? nil : (contents as? [IONContainerContent] ?? nil)
    }
}


public extension IONContainerContent {

    /// Provides typed content of a container content based on a given outlet identifier.
    /// - parameter identifier: The identifier of the child outlet (defined in ion desk)
    /// - parameter position: The content position within an outlet containing multiple contents (optional)
    func content<T: IONContent>(_ identifier: OutletIdentifier, at position: Position = 0) -> T? {

        guard let content = children.first(where: { $0.outlet == identifier && $0.position == position }) else {
            return nil
        }

        guard let typedContent = content as? T else {
            assertionFailure("Invalid content type requested (\(content.outlet))")
            return nil
        }

        return typedContent
    }
}


public extension IONContainerContent {

    func color(_ identifier: OutletIdentifier, at position: Position = 0) -> UIColor? {
        let colorContent: IONColorContent? = content(identifier, at: position)
        return colorContent?.color()
    }
}


public extension IONContainerContent {

    func containerContent(_ identifier: OutletIdentifier, at position: Position = 0) -> IONContainerContent? {
        let containerContent: IONContainerContent? = content(identifier, at: position)
        return containerContent
    }
}


public extension IONContainerContent {

    func date(_ identifier: OutletIdentifier, at position: Position = 0) -> Date? {

        let dateTimeContent: IONDateTimeContent? = content(identifier, at: position)
        return dateTimeContent?.date
    }
}


public extension IONContainerContent {

    func fileData(_ identifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<Data> {
        let asyncResult = AsyncResult<Data>()

        let fileContent: IONFileContent? = content(identifier, at: position)

        fileContent?.data({ (result) in
            guard case .success(let data) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }

            asyncResult.execute(result: .success(data))
        })

        return asyncResult
    }
}


public extension IONContainerContent {

    func flag(_ identifier: OutletIdentifier, at position: Position = 0) -> Bool {

        guard let flagContent: IONFlagContent = content(identifier, at: position) else {
            return false
        }

        return flagContent.isEnabled
    }
}


public extension IONContainerContent {

    func image(_ identifier: OutletIdentifier, at position: Position = 0) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()

        guard let imageContent: IONImageContent = content(identifier, at: position) else {
            ION.config.responseQueue.async { asyncResult.execute(result: .failure(IONError.noData(nil))) }
            return asyncResult
        }

        imageContent.image(callback: { (result) in
            asyncResult.execute(result: result)
        })

        return asyncResult
    }


    func thumbnail(_ identifier: OutletIdentifier, at position: Position = 0, ofSize size: CGSize) -> AsyncResult<UIImage> {
        let asyncResult = AsyncResult<UIImage>()

        guard let imageContent: IONImageContent = content(identifier, at: position) else {
            ION.config.responseQueue.async { asyncResult.execute(result: .failure(IONError.noData(nil))) }
            return asyncResult
        }

        imageContent.thumbnail(withSize: size, callback: { (result) in

            guard case .success(let image) = result else {
                asyncResult.execute(result: .failure(result.error ?? IONError.didFail))
                return
            }

            asyncResult.execute(result: .success(UIImage(cgImage: image)))
        })

        return asyncResult
    }
}


public extension IONContainerContent {

    func mediaURL(_ identifier: OutletIdentifier, at position: Position = 0) -> URL? {

        let mediaContent: IONMediaContent? = content(identifier, at: position)
        return mediaContent?.url
    }

    func mediaLength(_ identifier: OutletIdentifier, at position: Position = 0) -> TimeInterval? {

        let mediaContent: IONMediaContent? = content(identifier, at: position)
        return mediaContent
            .flatMap({ $0.length })
            .flatMap({ TimeInterval($0) }) ?? nil
    }
}


public extension IONContainerContent {

    func number(_ identifier: OutletIdentifier, at position: Position = 0) -> Double? {

        let numberContent: IONNumberContent? = content(identifier, at: position)
        return numberContent?.value
    }
}


public extension IONContainerContent {

    func option(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {

        let optionContent: IONOptionContent? = content(identifier, at: position)
        return optionContent?.value
    }
}


public extension IONContainerContent {

    func text(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {

        let textContent: IONTextContent? = content(identifier, at: position)
        return textContent?.plainText()
    }


    func attributedText(_ identifier: OutletIdentifier, at position: Position = 0) -> NSAttributedString? {
        let textContent: IONTextContent? = content(identifier, at: position)
        return textContent?.attributedString()
    }


    func htmlText(_ identifier: OutletIdentifier, at position: Position = 0) -> String? {
        let textContent: IONTextContent? = content(identifier, at: position)
        return textContent?.htmlText()
    }
}


public extension IONContainerContent {

    func table(_ identifier: OutletIdentifier, at position: Position = 0) -> [[String?]]? {

        let tableContent: IONTableContent? = content(identifier, at: position)
        return tableContent?.table
    }
}


public extension IONContainerContent {

    func connection(_ identifier: OutletIdentifier, at position: Position = 0) -> (collectionIdentifier: CollectionIdentifier, pageIdentifier: PageIdentifier)? {
        guard let connectionContent: IONConnectionContent = content(identifier, at: position),
            let collectionIdentifier = connectionContent.collectionIdentifier,
            let pageIdentifier = connectionContent.pageIdentifier else {
                return nil
        }

        return (collectionIdentifier: collectionIdentifier, pageIdentifier: pageIdentifier)
    }


    func connectionPage(_ identifier: OutletIdentifier, at position: Position = 0, option: PageLoadingOption = .meta) -> AsyncResult<Page> {
        let asyncResult = AsyncResult<Page>()

        guard let connection = connection(identifier, at: position) else {
            ION.config.responseQueue.async(execute: {
                asyncResult.execute(result: .failure(IONError.didFail))
            })
            return asyncResult
        }

        ION.page(pageIdentifier: connection.pageIdentifier, in: connection.collectionIdentifier, option: option).onSuccess { (page) in
            asyncResult.execute(result: .success(page))
            }.onFailure { (error) in
                asyncResult.execute(result: .failure(error))
        }

        return asyncResult
    }
}
