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

extension ContentNode {
    public func renderHTMLFragment() -> String {
        var content: String = ""
        for child in self.children {
            content.append(child.renderHTML())
        }
        return content.trimmingCharacters(in: CharacterSet.newlines)
    }
    
    public func renderHTML() -> String {
        var content: String = ""
        for child in self.children {
            content.append(child.renderHTML())
        }

        switch self.type {
        // Document level
        case .document:
            return "<html>\n\t<head>\n\t\t<title>Untitled</title>\n\t</head>\n<body>\n\(content)</body>\n</html>"
            
        // Block level
        case .heading(let level):
            return "<h\(level)>\(content)</h\(level)>\n\n"
            
        case .unorderedList:
            return "\n<ul>\n\(content)</ul>\n"
            
        case .unorderedListItem:
            return "<li>\(content)</li>\n"

        case .orderedList:
            return "\n<ol>\n\(content)</ol>\n"
            
        case .orderedListItem:
            return "<li>\(content)</li>\n"

        case .codeBlock(let language, _):
            return "\n<pre><code class=\"lang-\(language)\">\(content)</code></pre>\n"
            
        case .paragraph:
            return "\n<p>\(content)</p>\n"
            
        case .quote:
            return "\n<blockquote>\(content)</blockquote>\n"
            
        // Inline
        case .plainText:
            return self.text
            
        case .strongText:
            return "<strong>\(content)</strong>"
            
        case .emphasizedText:
            return "<em>\(content)</em>"

        case .deletedText:
            return "<del>\(content)</del>"

        case .inlineCode:
            return "<code>\(content)</code>"

        case .link(let location):
            return "<a href=\"\(location)\">\(content)</a>"

        case .image(let location):
            return "<img src=\"\(location)\" alt=\"\(content)\">"
        }
    }
}
