//
//  error.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import DEjson

public struct AMPError {
	public static let Domain = "com.anfema.amp"
	
	public enum Code: ErrorType {
		case NoData
		case InvalidJSON(JSONObject?)
		case JSONObjectExpected(JSONObject?)
		case JSONArrayExpected(JSONObject?)
        case JSONArrayOrObjectExpected(JSONObject?)
		case UnknownContentType(String)
        case CollectionNotFound(String)
        case PageNotFound(String)
        case InvalidPageHierarchy(parent: String, child: String)
        case OutletNotFound(String)
	}

	/// Creates an `NSError` with the given error code and failure reason.
    ///
    ///	- Parameter code: The error code.
	/// - Returns: An `NSError` with the given error code and failure reason.
	public static func error(code: Code) -> NSError {
		var userInfo = [NSLocalizedFailureReasonErrorKey: "Unknown Error"]
		var numericalCode = -7000
		switch(code) {
		case .NoData:
			numericalCode = -7001
			userInfo[NSLocalizedFailureReasonErrorKey] = "No data received"
		case .InvalidJSON(let obj):
			numericalCode = -7002
			userInfo[NSLocalizedFailureReasonErrorKey] = "Invalid JSON response"
			if let json = obj {
				userInfo["object"] = JSONEncoder(json).prettyJSONString
			}
		case .JSONObjectExpected(let obj):
			numericalCode = -7003
			userInfo[NSLocalizedFailureReasonErrorKey] = "JSON Object expected"
			if let json = obj {
				userInfo["object"] = JSONEncoder(json).prettyJSONString
			}
		case .JSONArrayExpected(let obj):
			numericalCode = -7004
			userInfo[NSLocalizedFailureReasonErrorKey] = "JSON Array expected"
			if let json = obj {
				userInfo["object"] = JSONEncoder(json).prettyJSONString
			}
        case .JSONArrayOrObjectExpected(let obj):
            numericalCode = -7005
            userInfo[NSLocalizedFailureReasonErrorKey] = "JSON Array or Object expected"
            if let json = obj {
                userInfo["object"] = JSONEncoder(json).prettyJSONString
            }
		case .UnknownContentType(let str):
			numericalCode = -7006
			userInfo[NSLocalizedFailureReasonErrorKey] = "Unknown content type received"
			userInfo["contentType"] = str
        case .CollectionNotFound(let name):
            numericalCode = -7007
            userInfo[NSLocalizedFailureReasonErrorKey] = "Collection not found"
            userInfo["name"] = name
        case .PageNotFound(let name):
            numericalCode = -7008
            userInfo[NSLocalizedFailureReasonErrorKey] = "Page not found"
            userInfo["name"] = name
        case .InvalidPageHierarchy(let parent, let child):
            numericalCode = -7009
            userInfo[NSLocalizedFailureReasonErrorKey] = "Invalid page hierarchy, child does not belong to parent"
            userInfo["parent"] = parent
            userInfo["child"] = child
        case .OutletNotFound(let name):
            numericalCode = -7010
            userInfo[NSLocalizedFailureReasonErrorKey] = "Outlet not found"
            userInfo["name"] = name
		}
        
		return NSError(domain: Domain, code: numericalCode, userInfo: userInfo)
	}
}
