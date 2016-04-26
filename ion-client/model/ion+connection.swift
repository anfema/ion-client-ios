//
//  ion+connection.swift
//  ion-client
//
//  Created by Dominik Felber on 20.04.16.
//  Copyright © 2016 anfema GmbH. All rights reserved.
//

import Foundation


extension ION {
    /// Tries to fetch the associated collection
    /// - parameter      url: The URL the collection identifier should be extracted from to request the collection.
    /// - parameter callback: Result object either containing the IONCollection in succes case or an IONError
    ///                       when the collection could not be resolved.
    public class func resolve(url: NSURL, callback: (Result<IONCollection, IONError> -> Void)) {
        guard let identifier = url.host else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        collection(identifier, callback: callback)
    }
    
    
    /// Tries to fetch the associated page
    /// - parameter      url: The URL the page identifier should be extracted from to request the page.
    /// - parameter callback: Result object either containing the IONPage in succes case or an IONError
    ///                       when the page could not be resolved.
    public class func resolve(url: NSURL, callback: (Result<IONPage, IONError> -> Void)) {
        guard let identifier = url.lastPathComponent where identifier != "/" else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        resolve(url) { (result: Result<IONCollection, IONError>) in
            guard case .Success(let collection) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            collection.page(identifier, callback: callback)
        }
    }
    
    
    /// Tries to fetch the associated outlet
    /// - parameter      url: The URL the outlet name should be extracted from to request the outlet.
    /// - parameter callback: Result object either containing the IONContent in succes case or an IONError
    ///                       when the outlet could not be resolved.
    public class func resolve(url: NSURL, callback: (Result<IONContent, IONError> -> Void)) {
        guard let name = url.fragment else {
            responseQueueCallback(callback, parameter: .Failure(.DidFail))
            return
        }
        
        resolve(url) { (result: Result<IONPage, IONError>) in
            guard case .Success(let page) = result else {
                responseQueueCallback(callback, parameter: .Failure(result.error ?? .UnknownError))
                return
            }
            
            page.outlet(name, callback: callback)
        }
    }
}