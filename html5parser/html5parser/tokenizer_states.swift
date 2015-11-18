//
//  tokenizer_states.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

internal enum TokenizerState {
    case Data
    case CharacterReference
    case TagOpen
    case EndTagOpen
    case TagName
    
    case AttributeNameBefore
    case AttributeName
    case AttributeNameAfter
    case AttributeValueBefore
    case AttributeValueSingleQuote
    case AttributeValueDoubleQuote
    case AttributeValueUnquoted
    case AttributeValueAfter
    case SelfClosingStartTag

    // Tags that start with !
    case MarkupDeclarationOpen

    // Comments
    case BogusComment
    case CommentStart
    case CommentStartDash
    case Comment
    case CommentEndDash
    case CommentEnd
    case CommentEndBang
    
    // CDATA
    case CDATA
    case CDATAEndBracket
    case CDATAEndTag
    
    // Doctype (not implemented)
    case Doctype
    case DoctypeBeforeName
    case DoctypeName
    case DoctypeNameAfter
    case DoctypePublicAfter
    case DoctypePublicIdentifierBefore
    case DoctypePublicIdentifierDoubleQuoted
    case DoctypePublicIdentifierSingleQuoted
    case DoctypePublicIdentifierAfter
    case DoctypeBetweenPublicAndSystem
    case DoctypeSystemAfter
    case DoctypeSystemIdentifierBefore
    case DoctypeSystemIdentifierDoubleQuoted
    case DoctypeSystemIdentifierSingleQuoted
    case DoctypeSystemIdentifierAfter
    case DoctypeBogus
    
}

internal enum CharRefState {
    case NamedChar
    case Number
    case HexNumber
}