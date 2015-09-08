//
//  error.swift
//  amp-client
//
//  Created by Johannes Schriewer on 08.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

public struct AMPError {
	public static let Domain = "com.anfema.amp"
	
	public enum Code: ErrorType {
		case NoData
		case InvalidJSON(JSONObject?)
		case JSONObjectExpected(JSONObject?)
		case JSONArrayExpected(JSONObject?)
		case UnknownContentType(String)
	}

	/**
	Creates an `NSError` with the given error code and failure reason.
	
	- parameter code:          The error code.
	- parameter failureReason: The failure reason.
	
	- returns: An `NSError` with the given error code and failure reason.
	*/
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
		case .UnknownContentType(let str):
			numericalCode = -7005
			userInfo[NSLocalizedFailureReasonErrorKey] = "Unknown content type received"
			userInfo["contentType"] = str
		}
		return NSError(domain: Domain, code: numericalCode, userInfo: userInfo)
	}
}
