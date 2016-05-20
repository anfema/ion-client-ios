//
//  response_serializer.swift
//  ion-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Alamofire
import DEjson

/// JSON response object, contains json and status code
public struct JSONResponse {

    /// Decoded JSON object
    public let json: JSONObject?

    /// HTTP status code of response
    public let statusCode: Int

    /// Initializer
    ///
    /// - parameter json: optional, decoded `JSONObject` of the response
    /// - parameter statusCode: HTTP status code of the response
    public init(json: JSONObject?, statusCode: Int = 200) {
        self.json = json
        self.statusCode = statusCode
    }
}

/// Extend Alamofire Request with JSON response serializer of own JSON parser
extension Request {

    /// Creates a response serializer that returns an JSON object constructed from the response data
    ///
    /// - returns: A `JSONObject` response serializer
    static func DEJSONResponseSerializer() -> ResponseSerializer<JSONResponse, IONError> {
        return ResponseSerializer { _, response, data, error in
            guard let validData = data, response = response else {
                return .Failure(.ServerUnreachable)
            }

            switch response.statusCode {
            case 401, 403:
                return .Failure(.NotAuthorized)
            case 500...511:
                return .Failure(.ServerUnreachable)
            case 304:
                return .Success(JSONResponse(json: nil, statusCode: 304))
            case 200:
                break // everything is fine
            default:
                return .Failure(.NoData(error))
            }

            guard let jsonString = String(data: validData, encoding: NSUTF8StringEncoding) else {
                return .Failure(.InvalidJSON(nil))
            }

            let JSON = JSONDecoder(jsonString).jsonObject
            if case .JSONInvalid = JSON {
                return .Failure(.InvalidJSON(nil))
            }

            return .Success(JSONResponse(json: JSON))
        }
    }

    /// Adds a handler to be called once the request has finished.
    ///
    /// - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 3
    ///                                arguments: the URL request, the URL response and the result produced while
    ///                                creating the JSON object.
    /// - returns: The request.
    func responseDEJSON(
        completionHandler: Response<JSONResponse, IONError> -> Void)
        -> Self {
        return response(
            responseSerializer: Request.DEJSONResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}
