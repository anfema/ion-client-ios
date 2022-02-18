//
//  html_renderer.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

// TODO: Add tests for text renderer

extension ContentNode {
    
    public func renderText() -> String {
        var content: String = ""
        for child in self.children {
            content.append(child.renderText())
        }

        switch self.type {
        // Document level
        case .document:
            return content
            
        // Block level
        case .heading:
            return "\n\(content)\n\n"
            
        case .unorderedList:
            return "\n\(content)\n"
            
        case .unorderedListItem:
            return "\(content)\n"

        case .orderedList:
            return "\n\(content)\n"
            
        case .orderedListItem:
            return "\(content)\n"

        case .codeBlock:
            return "\n\(content)\n\n"
            
        case .paragraph:
            return "\n\(content)\n\n"
            
        case .quote:
            return "\n\(content)\n\n"
            
        // Inline
        case .plainText:
            return self.text
            
        case .strongText:
            return content
            
        case .emphasizedText:
            return content

        case .deletedText:
            return ""

        case .inlineCode:
            return content

        case .link:
            return content

        case .image:
            return content
        }
    }
}
