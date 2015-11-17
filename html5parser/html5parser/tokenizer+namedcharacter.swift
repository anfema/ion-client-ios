//
//  tokenizer+namedcharacter.swift
//  html5parser
//
//  Created by Johannes Schriewer on 17/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import Foundation

extension HTML5Tokenizer {
    func parseNamedChar(characterName: String) -> UnicodeScalar {
        switch characterName {
        case "amp":
            return "&"
        case "ouml":
            return "ö"
        case "Ouml":
            return "Ö"
        case "uuml":
            return "ü"
        case "Uuml":
            return "Ü"
        case "auml":
            return "ä"
        case "Auml":
            return "Ä"
        case "szlig":
            return "ß"
        default:
            return "?"
        }
    }
}

// TODO: Support more named characters