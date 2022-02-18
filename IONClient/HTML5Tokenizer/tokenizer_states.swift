//
//  tokenizer_states.swift
//  html5tokenizer
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

internal enum TokenizerState {
    case data
    case characterReference
    case tagOpen
    case endTagOpen
    case tagName

    case attributeNameBefore
    case attributeName
    case attributeNameAfter
    case attributeValueBefore
    case attributeValueSingleQuote
    case attributeValueDoubleQuote
    case attributeValueUnquoted
    case attributeValueAfter
    case selfClosingStartTag

    // Tags that start with !
    case markupDeclarationOpen

    // Comments
    case bogusComment
    case commentStart
    case commentStartDash
    case comment
    case commentEndDash
    case commentEnd
    case commentEndBang

    // CDATA
    case cdata
    case cdataEndBracket
    case cdataEndTag

    // Doctype (not implemented)
    case doctype
    case doctypeBeforeName
    case doctypeName
    case doctypeNameAfter
    case doctypePublicAfter
    case doctypePublicIdentifierBefore
    case doctypePublicIdentifierDoubleQuoted
    case doctypePublicIdentifierSingleQuoted
    case doctypePublicIdentifierAfter
    case doctypeBetweenPublicAndSystem
    case doctypeSystemAfter
    case doctypeSystemIdentifierBefore
    case doctypeSystemIdentifierDoubleQuoted
    case doctypeSystemIdentifierSingleQuoted
    case doctypeSystemIdentifierAfter
    case doctypeBogus

}

internal enum CharRefState {
    case namedChar
    case number
    case hexNumber
}
