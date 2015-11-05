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
            content.appendContentsOf(child.renderText())
        }

        switch self.type {
        // Document level
        case .Document:
            return content
            
        // Block level
        case .Heading:
            return "\n\(content)\n\n"
            
        case .UnorderedList:
            return "\n\(content)\n"
            
        case .UnorderedListItem:
            return "\(content)\n"

        case .OrderedList:
            return "\n\(content)\n"
            
        case .OrderedListItem:
            return "\(content)\n"

        case .CodeBlock:
            return "\n\(content)\n\n"
            
        case .Paragraph:
            return "\n\(content)\n\n"
            
        case .Quote:
            return "\n\(content)\n\n"
            
        // Inline
        case .PlainText:
            return self.text
            
        case .StrongText:
            return content
            
        case .EmphasizedText:
            return content

        case .DeletedText:
            return ""

        case .InlineCode:
            return content

        case .Link:
            return content

        case .Image:
            return content
        }
    }
}
