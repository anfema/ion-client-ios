//
//  response_serializer.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Alamofire
import DEjson

extension Request {
    
    /**
    Creates a response serializer that returns an AMP object constructed from the response data
    
    - returns: An AMP object response serializer.
    */
    public static func DEJSONResponseSerializer() -> GenericResponseSerializer<JSONObject> {
        return GenericResponseSerializer { _, _, data in
            guard let validData = data else {
                let error = AMPError.error(AMPError.Code.NoData)
                return .Failure(data, error)
            }
            
            if let jsonString = String(data: validData, encoding: NSUTF8StringEncoding) {
                let JSON = JSONDecoder(jsonString).jsonObject
                if case .JSONInvalid = JSON {
                    return .Failure(data, AMPError.error(AMPError.Code.InvalidJSON(nil)))
                }
                return .Success(JSON)
            } else {
                return .Failure(data, AMPError.error(AMPError.Code.InvalidJSON(nil)))
            }
        }
    }
    
    /**
    Adds a handler to be called once the request has finished.
    
    - parameter completionHandler: A closure to be executed once the request has finished. The closure takes 3
    arguments: the URL request, the URL response and the result produced while
    creating the AMP object.
    
    - returns: The request.
    */
    public func responseDEJSON(
        completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<JSONObject>) -> Void)
        -> Self
    {
        return response(
            responseSerializer: Request.DEJSONResponseSerializer(),
            completionHandler: completionHandler
        )
    }
}
