//
//  tokens.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

public enum HTML5Token {
    case DocType(name:String?, publicID:String?, systemID:String?, forceQuirks:Bool)
    case StartTag(name:String?, selfClosing: Bool, attributes:[String:String]?)
    case EndTag(name:String?)
    case Comment(data:String?)
    case Text(data:String?)
    case EOF
}