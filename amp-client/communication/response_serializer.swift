//
//  response_serializer.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Alamofire
import DEjson

/// Extend Alamofire Request with JSON response serializer of own JSON parser
extension Request {
    
    /// Creates a response serializer that returns an JSON object constructed from the response data
    ///
    /// - returns: A `JSONObject` response serializer
    public static func DEJSONResponseSerializer() -> ResponseSerializer<JSONObject, AMPError> {
        return ResponseSerializer { _, response, data, error in
            guard let validData = data where response != nil else {
                return .Failure(.NoData(error))
            }
            
            if response!.statusCode == 401 || response!.statusCode == 403 {
                return .Failure(.NotAuthorized)
            }
            
            if response!.statusCode != 200 {
                return .Failure(.NoData(error))
            }
            
            if let jsonString = String(data: validData, encoding: NSUTF8StringEncoding) {
                let JSON = JSONDecoder(jsonString).jsonObject
                if case .JSONInvalid = JSON {
                    return .Failure(.InvalidJSON(nil))
                }
                return .Success(JSON)
            } else {
                return .Failure(.InvalidJSON(nil))
            }
        }
    }
    
    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 3
    ///                                arguments: the URL request, the URL response and the result produced while
    ///                                creating the JSON object.
    /// - returns: The request.
    public func responseDEJSON(
        completionHandler: Response<JSONObject, AMPError> -> Void)
        -> Self
    {
        return response(
            responseSerializer: Request.DEJSONResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}
