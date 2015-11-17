//
//  tokenizer_states.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

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
    
    // Doctype
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