//
//  html_renderer.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import Foundation

extension ContentNode {
    public func renderHTMLFragment() -> String {
        var content: String = ""
        for child in self.children {
            content.appendContentsOf(child.renderHTML())
        }
        return content.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
    }
    
    public func renderHTML() -> String {
        var content: String = ""
        for child in self.children {
            content.appendContentsOf(child.renderHTML())
        }

        switch self.type {
        // Document level
        case .Document:
            return "<html>\n\t<head>\n\t\t<title>Untitled</title>\n\t</head>\n<body>\n\(content)</body>\n</html>"
            
        // Block level
        case .Heading(let level):
            return "<h\(level)>\(content)</h\(level)>\n\n"
            
        case .UnorderedList:
            return "\n<ul>\n\(content)</ul>\n"
            
        case .UnorderedListItem:
            return "<li>\(content)</li>\n"

        case .OrderedList:
            return "\n<ol>\n\(content)</ol>\n"
            
        case .OrderedListItem:
            return "<li>\(content)</li>\n"

        case .CodeBlock(let language):
            return "\n<pre><code class=\"lang-\(language)\">\(content)</code></pre>\n"
            
        case .Paragraph:
            return "\n<p>\(content)</p>\n"
            
        case .Quote:
            return "\n<blockquote>\(content)</blockquote>\n"
            
        // Inline
        case .PlainText:
            return self.text
            
        case .StrongText:
            return "<strong>\(content)</strong>"
            
        case .EmphasizedText:
            return "<em>\(content)</em>"

        case .DeletedText:
            return "<del>\(content)</del>"

        case .InlineCode:
            return "<code>\(content)</code>"

        case .Link(let location):
            return "<a href=\"\(location)\">\(content)</a>"

        case .Image(let location):
            return "<img src=\"\(location)\" alt=\"\(content)\">"
        }
    }
}
