//
//  content.swift
//  amp-client
//
//  Created by Johannes Schriewer on 07.09.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation
import UIKit

public class AMPContentBase : AMPObject {
	var variation:String  = "default"
	var outlet:String?    = nil
	var isSearchable:Bool = false

	init(withJSON json:JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONString(let variation)   = dict["variation"]!     where (dict["variation"] != nil),
			  case .JSONString(let outlet)      = dict["outlet"]!        where (dict["outlet"] != nil),
			  case .JSONBoolean(let searchable) = dict["is_searchable"]! where (dict["is_searchable"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}
		
		self.variation = variation
		self.outlet = outlet
		self.isSearchable = searchable
	}
}

public class AMPColorContent : AMPContentBase {
	var r:Int = 0
	var g:Int = 0
	var b:Int = 0
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)

		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONNumber(let r) = dict["r"]! where (dict["r"] != nil),
			  case .JSONNumber(let g) = dict["g"]! where (dict["g"] != nil),
			  case .JSONNumber(let b) = dict["b"]! where (dict["b"] != nil) else {
				throw AMPError.Code.InvalidJSON(json)
		}
		
		self.r = Int(r)
		self.g = Int(g)
		self.b = Int(b)
	}
}

public class AMPContainerContent : AMPContentBase {
	var children:Array<AMPContent>? = nil

	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONArray(let children) = dict["children"]! where dict["children"] != nil else {
			throw AMPError.Code.JSONArrayExpected(json)
		}
		
		self.children = []
		for child in children {
			try self.children!.append(AMPContent(withJSON: child))
		}
	}
	
	subscript(index: Int) -> AMPContent? {
		guard self.children != nil && index < self.children!.count else {
			return nil
		}
		return self.children![index]
	}
}

public class AMPDateTimeContent : AMPContentBase {
	public var date:NSDate? = nil

	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}

		guard case .JSONString(let datetime) = dict["datetime"]! where (dict["datetime"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}
		
		let fmt = NSDateFormatter()
		fmt.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"
		fmt.timeZone   = NSTimeZone(forSecondsFromGMT: 0)
		fmt.locale     = NSLocale(localeIdentifier: "en_US_POSIX")

		self.date = fmt.dateFromString(datetime)
	}
}

public class AMPFileContent : AMPContentBase {
	var mimeType:String = "application/octet-stream"
	var fileName:String = "file.dat"
	var size:Int        = 0
	var checksum:String = "null:"
	var url:NSURL?      = nil

	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONString(let mimeType) = dict["mime_type"]! where (dict["mime_type"] != nil),
			  case .JSONString(let fileName) = dict["name"]!      where (dict["name"] != nil),
			  case .JSONNumber(let size)     = dict["file_size"]! where (dict["file_size"] != nil),
			  case .JSONString(let checksum) = dict["checksum"]!  where (dict["checksum"] != nil),
			  case .JSONString(let fileUrl)  = dict["file"]!      where (dict["file"] != nil) else {
				throw AMPError.Code.InvalidJSON(json)
		}

		self.mimeType = mimeType
		self.fileName = fileName
		self.size     = Int(size)
		self.checksum = checksum
		self.url      = NSURL(string: fileUrl)
	}

	func data() -> NSData? {
		// TODO: fetch data from cache
		return nil
	}
}

public class AMPFlagContent : AMPContentBase {
	var enabled:Bool = false

	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONBoolean(let enabled) = dict["enabled"]! where (dict["enabled"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}

		self.enabled = enabled
	}
}

public class AMPImageContent : AMPContentBase {
	var mimeType:String			= "application/octet-stream"
	var size:CGSize				= CGSizeZero
	var fileSize:Int			= 0
	var url:NSURL?				= nil
	var originalMimeType:String	= "application/octet-stream"
	var originalSize:CGSize		= CGSizeZero
	var originalFileSize:Int	= 0
	var originalURL:NSURL?		= nil
	var translation:CGPoint		= CGPointZero
	var scale:Float				= 1.0
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}

		guard case .JSONString(let mimeType)  = dict["mime_type"]!          where (dict["mime_type"] != nil),
			  case .JSONString(let oMimeType) = dict["original_mime_type"]! where (dict["original_mime_type"] != nil),
			  case .JSONString(let fileUrl)   = dict["image"]!              where (dict["image"] != nil),
			  case .JSONString(let oFileUrl)  = dict["original_image"]!     where (dict["original_image"] != nil),
			  case .JSONNumber(let width)     = dict["width"]!              where (dict["width"] != nil),
			  case .JSONNumber(let height)    = dict["height"]!             where (dict["height"] != nil),
			  case .JSONNumber(let oWidth)    = dict["original_width"]!     where (dict["original_width"] != nil),
			  case .JSONNumber(let oHeight)   = dict["original_height"]!    where (dict["original_height"] != nil),
			  case .JSONNumber(let fileSize)  = dict["file_size"]!          where (dict["file_size"] != nil),
			  case .JSONNumber(let oFileSize) = dict["original_file_size"]! where (dict["original_file_size"] != nil),
			  case .JSONNumber(let scale)     = dict["scale"]!              where (dict["scale"] != nil),
			  case .JSONNumber(let transX)    = dict["translation_x"]!      where (dict["translation_x"] != nil),
			  case .JSONNumber(let transY)    = dict["translation_y"]!      where (dict["translation_y"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}

		self.mimeType = mimeType
		self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
		self.fileSize = Int(fileSize)
		self.url      = NSURL(string: fileUrl)

		self.translation = CGPointMake(CGFloat(transX), CGFloat(transY))
		self.scale       = Float(scale)

		self.originalMimeType = oMimeType
		self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
		self.originalFileSize = Int(oFileSize)
		self.originalURL      = NSURL(string: oFileUrl)
	}
	
	func image() -> CGImageRef? {
		// TODO: fetch data from cache
		return nil
	}
	
	func image() -> UIImage? {
		// TODO: fetch data from cache
		return nil
	}
}

public class AMPKeyValueContent : AMPContentBase {
	private var values:Dictionary<String, AnyObject>? = nil
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONDictionary(let values) = dict["values"]! where (dict["values"] != nil) else {
			throw AMPError.Code.JSONObjectExpected(dict["values"])
		}
		
		self.values = Dictionary()
		for (key, valueObj) in values {
			switch (valueObj) {
			case .JSONString(let str):
				self.values!.updateValue(str, forKey: key)
			case .JSONNumber(let number):
				self.values!.updateValue(number, forKey: key)
			case .JSONBoolean(let boolean):
				self.values!.updateValue(boolean, forKey: key)
			default:
				throw AMPError.Code.InvalidJSON(valueObj)
			}
		}
	}
	
	subscript(index: String) -> AnyObject? {
		if let values = self.values {
			return values[index]
		}
		return nil
	}
}

public class AMPMediaContent : AMPContentBase {
	var mimeType:String			= "application/octet-stream"
	var size:CGSize				= CGSizeZero
	var fileSize:Int			= 0
	var checksum:String			= "null:"
	var length:Float			= 0.0
	var url:NSURL?				= nil
	
	var originalMimeType:String	= "application/octet-stream"
	var originalSize:CGSize		= CGSizeZero
	var originalFileSize:Int	= 0
	var originalChecksum:String	= "null:"
	var originalLength:Float	= 0.0
	var originalURL:NSURL?		= nil
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONString(let mimeType)  = dict["mime_type"]!          where (dict["mime_type"] != nil),
			  case .JSONString(let oMimeType) = dict["original_mime_type"]! where (dict["original_mime_type"] != nil),
			  case .JSONString(let fileUrl)   = dict["image"]!              where (dict["image"] != nil),
			  case .JSONString(let oFileUrl)  = dict["original_image"]!     where (dict["original_image"] != nil),
			  case .JSONNumber(let width)     = dict["width"]!              where (dict["width"] != nil),
			  case .JSONNumber(let height)    = dict["height"]!             where (dict["height"] != nil),
			  case .JSONNumber(let oWidth)    = dict["original_width"]!     where (dict["original_width"] != nil),
			  case .JSONNumber(let oHeight)   = dict["original_height"]!    where (dict["original_height"] != nil),
			  case .JSONNumber(let fileSize)  = dict["file_size"]!          where (dict["file_size"] != nil),
			  case .JSONNumber(let oFileSize) = dict["original_file_size"]! where (dict["original_file_size"] != nil),
			  case .JSONString(let checksum)  = dict["checksum"]!           where (dict["checksum"] != nil),
			  case .JSONString(let oChecksum) = dict["original_checksum"]!  where (dict["original_checksum"] != nil),
			  case .JSONNumber(let length)    = dict["length"]!             where (dict["length"] != nil),
			  case .JSONNumber(let oLength)   = dict["original_length"]!    where (dict["original_length"] != nil) else {
				throw AMPError.Code.InvalidJSON(json)
		}
		
		self.mimeType = mimeType
		self.size     = CGSizeMake(CGFloat(width), CGFloat(height))
		self.fileSize = Int(fileSize)
		self.url      = NSURL(string: fileUrl)
		self.checksum = checksum
		self.length   = Float(length)
		
		self.originalMimeType = oMimeType
		self.originalSize     = CGSizeMake(CGFloat(oWidth), CGFloat(oHeight))
		self.originalFileSize = Int(oFileSize)
		self.originalURL      = NSURL(string: oFileUrl)
		self.originalChecksum = oChecksum
		self.originalLength   = Float(oLength)

	}
}

public class AMPOptionContent : AMPContentBase {
	var value:String? = nil
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONString(let value) = dict["value"]! where (dict["value"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}

		self.value = value
	}
}

public class AMPTextContent : AMPContentBase {
	var mimeType:String = "text/plain"
	var multiLine:Bool  = false
	var text:String     = ""
	
	override init(withJSON json:JSONObject) throws {
		try super.init(withJSON: json)
		
		guard case .JSONDictionary(let dict) = json else {
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case .JSONString(let mimeType) = dict["mime_type"]! where (dict["mime_type"] != nil),
			  case .JSONBoolean(let multiLine) = dict["multi_line"]! where (dict["multi_line"] != nil),
			  case .JSONString(let text) = dict["text"]! where (dict["text"] != nil) else {
			throw AMPError.Code.InvalidJSON(json)
		}
		
		self.mimeType = mimeType
		self.multiLine = multiLine
		self.text = text
	}
	
	public func htmlText() -> String? {
		switch (self.mimeType) {
		case "text/html":
			return self.text
		case "text/markdown":
			// TODO: convert Markdown to HTML
			return self.text
		case "text/plain":
			// FIXME: Wrap somehow?
			return self.text
		default:
			return nil
		}
	}
	
	public func attributedString() -> NSAttributedString? {
		switch (self.mimeType) {
		case "text/html":
			// TODO: Speed this up
			if let data = self.text.dataUsingEncoding(NSUTF8StringEncoding) {
				do {
					return try NSAttributedString(
							data: data,
							options: [
								NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType,
								NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
							],
							documentAttributes: nil
					)
				} catch {
					return nil
				}
			} else {
				return nil
			}
		case "text/markdown":
			// TODO: Parse markdown
			return NSAttributedString(string: self.text)
		case "text/plain":
			return NSAttributedString(string: self.text)
		default:
			return nil
		}
	}
	
	public func plainText() -> String? {
		switch(self.mimeType) {
		case "text/plain":
			return self.text
		case "text/html":
			// TODO: Strip tags
			return self.text
		case "text/markdown":
			// TODO: Strip markup
			return self.text
		default:
			// Unknown content type, just assume user wants no alterations
			return self.text
		}
	}
}

public enum AMPContent {
	case Color(AMPColorContent)
	case Container(AMPContainerContent)
	case DateTime(AMPDateTimeContent)
	case File(AMPFileContent)
	case Flag(AMPFlagContent)
	case Image(AMPImageContent)
	case KeyValue(AMPKeyValueContent)
	case Media(AMPMediaContent)
	case Option(AMPOptionContent)
	case Text(AMPTextContent)
	case Invalid
	
	public init(withJSON json:JSONObject) throws {
		guard case .JSONDictionary(let dict) = json else {
			self = .Invalid
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		guard case let contentTypeObj = dict["content_type"]! where dict["content_type"] != nil,
			  case .JSONString(let contentType) = contentTypeObj else {
			self = .Invalid
			throw AMPError.Code.JSONObjectExpected(json)
		}
		
		switch(contentType) {
		case "colorcontent":
			try self = .Color(AMPColorContent(withJSON: json))
		case "containercontent":
			try self = .Container(AMPContainerContent(withJSON: json))
		case "datetimecontent":
			try self = .DateTime(AMPDateTimeContent(withJSON: json))
		case "filecontent":
			try self = .File(AMPFileContent(withJSON: json))
		case "flagcontent":
			try self = .Flag(AMPFlagContent(withJSON: json))
		case "imagecontent":
			try self = .Image(AMPImageContent(withJSON: json))
		case "kvcontent":
			try self = .KeyValue(AMPKeyValueContent(withJSON: json))
		case "mediacontent":
			try self = .Media(AMPMediaContent(withJSON: json))
		case "optioncontent":
			try self = .Option(AMPOptionContent(withJSON: json))
		case "textcontent":
			try self = .Text(AMPTextContent(withJSON: json))
		default:
			self = .Invalid
			throw AMPError.Code.UnknownContentType(contentType)
		}
	}
}

