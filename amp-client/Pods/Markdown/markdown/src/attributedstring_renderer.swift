//
//  attributedstring_renderer.swift
//  markdown
//
//  Created by Johannes Schriewer on 07.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted under the conditions of the 3-clause
// BSD license (see LICENSE.txt for full license text)

import Foundation

#if os(iOS)
    public typealias Font = UIFont
    public typealias Color = UIColor
#else
    public typealias Font = NSFont
    public typealias Color = NSColor
#endif

public struct AttributedStringStyle {
    public var font: Font?
    public var foregroundColor: Color?
    public var backgroundColor: Color?
    public var underline:Bool?
    public var strikeThrough:Bool?
    
    public var alignment:NSTextAlignment?
    public var textIndent:Int?
    public var lineHeightMultiplier:Float?
    public var lineBreakMode: NSLineBreakMode?
    
    public var marginTop:Float?
    public var marginBottom:Float?
    
    public var writingDirection:NSWritingDirection?
    
    func makeAttributeDict() -> Dictionary<String, AnyObject> {
        var result = Dictionary<String, AnyObject>()
        
        if let font = self.font {
            result[NSFontAttributeName] = font
        }
        if let foregroundColor = self.foregroundColor {
            result[NSForegroundColorAttributeName] = foregroundColor
        }
        if let backgroundColor = self.backgroundColor {
            result[NSBackgroundColorAttributeName] = backgroundColor
        }
        if let underline = self.underline {
            result[NSUnderlineStyleAttributeName] = (underline ? NSUnderlineStyle.StyleSingle.rawValue : NSUnderlineStyle.StyleNone.rawValue)
        }
        if let strikeThrough = self.strikeThrough {
            result[NSStrikethroughStyleAttributeName] = (strikeThrough ? NSUnderlineStyle.StyleSingle.rawValue : NSUnderlineStyle.StyleNone.rawValue)
        }
        
        var useParagraphStyle = false
        let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
        
        if let alignment = self.alignment {
            useParagraphStyle = true
            paragraphStyle.alignment = alignment
        }

        if let textIndent = self.textIndent {
            useParagraphStyle = true
            paragraphStyle.firstLineHeadIndent = CGFloat(textIndent)
            paragraphStyle.headIndent = CGFloat(textIndent)
        }

        if let lineHeightMultiplier = self.lineHeightMultiplier {
            useParagraphStyle = true
            paragraphStyle.lineHeightMultiple = CGFloat(lineHeightMultiplier)
        }

        if let lineBreakMode = self.lineBreakMode {
            useParagraphStyle = true
            paragraphStyle.lineBreakMode = lineBreakMode
        }

        if let marginTop = self.marginTop {
            useParagraphStyle = true
            paragraphStyle.paragraphSpacingBefore = CGFloat(marginTop)
        }

        if let marginBottom = self.marginBottom {
            useParagraphStyle = true
            paragraphStyle.paragraphSpacing = CGFloat(marginBottom)
        }

        if let writingDirection = self.writingDirection {
            useParagraphStyle = true
            paragraphStyle.baseWritingDirection = writingDirection
        }

        if useParagraphStyle {
            result[NSParagraphStyleAttributeName] = paragraphStyle
        }
        
        return result
    }
    
    public func addTabstop(location: Float) {
        // TODO: add tabstop
    }
}

public struct AttributedStringStyling {
    var heading:[AttributedStringStyle]
    var unorderedList:AttributedStringStyle
    var unorderedListItem:AttributedStringStyle
    var orderedList:AttributedStringStyle
    var orderedListItem:AttributedStringStyle
    var codeBlock:AttributedStringStyle
    var paragraph:AttributedStringStyle
    var quoteBlock:AttributedStringStyle

    var strongText:AttributedStringStyle
    var emphasizedText:AttributedStringStyle
    var deletedText:AttributedStringStyle
    var inlineCode:AttributedStringStyle
    var link:AttributedStringStyle
    
    var embedImages:Bool
    
    public init() {
        #if os(iOS)
            self.init(font: UIFont.systemFontOfSize(17.0),
                strongFont: UIFont.boldSystemFontOfSize(17.0),
                emphasizedFont: UIFont.italicSystemFontOfSize(17.0),
                baseColor: UIColor.blackColor(),
                backgroundColor: UIColor.whiteColor())
        #else
            self.init(font: NSFont(name: "Helvetica", size: 16.0)!,
                strongFont: NSFont(name: "Helvetica-Bold", size: 16.0)!,
                emphasizedFont: NSFont(name: "Helvetica-Oblique", size: 16.0)!,
                baseColor: NSColor.blackColor(),
                backgroundColor: NSColor.whiteColor())
        #endif
    }
    
    public init(font: Font, strongFont: Font, emphasizedFont: Font, baseColor: Color, backgroundColor: Color) {
        var indent = AttributedStringStyle()
        indent.textIndent = Int(font.pointSize)
        self.unorderedList = indent
        self.orderedList = indent
        
        let listItems = AttributedStringStyle()
        // FIXME: multi line items do not indent correctly
        self.unorderedListItem = listItems
        self.orderedListItem = listItems
        
        var codeBlock = AttributedStringStyle()
        codeBlock.textIndent = Int(font.pointSize)
        #if os(iOS)
            codeBlock.font = UIFont(name: "Courier", size: font.pointSize)
        #else
            codeBlock.font = NSFont(name: "Courier", size: font.pointSize)
        #endif
        self.codeBlock = codeBlock
        
        var paragraph = AttributedStringStyle()
        paragraph.font = font
        paragraph.foregroundColor = baseColor
        paragraph.backgroundColor = backgroundColor
        self.paragraph = paragraph
        
        var quote = AttributedStringStyle()
        quote.textIndent = Int(font.pointSize)
        self.quoteBlock = quote
        
        var strong = AttributedStringStyle()
        strong.font = strongFont
        self.strongText = strong
        
        var em = AttributedStringStyle()
        em.font = emphasizedFont
        self.emphasizedText = em
        
        var delete = AttributedStringStyle()
        delete.strikeThrough = true
        self.deletedText = delete
        
        var inlineCode = AttributedStringStyle()
        inlineCode.font = codeBlock.font
        self.inlineCode = inlineCode
        
        var link = AttributedStringStyle()
        link.underline = true
        #if os(iOS)
            link.foregroundColor = UIColor.blueColor()
        #else
            link.foregroundColor = NSColor.blueColor()
        #endif
        self.link = link
        
        self.embedImages = false
        
        self.heading = []
        self.calculateHeadingSizes(1.1, font: font)
    }
    
    public mutating func calculateHeadingSizes(multiplier: Float, font: Font) {
        self.heading.removeAll()
        for i in 0...4 {
            let fontSize = Float(font.pointSize) * powf(1.1, Float(5 - i))
            #if os(iOS)
                let f = UIFont(name:font.fontName, size: CGFloat(fontSize))
                #else
                let f = NSFont(name:font.fontName, size: CGFloat(fontSize))
            #endif
            var settings = AttributedStringStyle()
            settings.font = f
            settings.marginTop = fontSize / 2.0
            settings.marginBottom = fontSize
            
            self.heading.append(settings)
        }
    }
}

extension ContentNode {
    
    public func renderAttributedString(style: AttributedStringStyling) -> NSAttributedString {
        let content = NSMutableAttributedString(string: "")
        for child in self.children {
            content.appendAttributedString(child.renderAttributedString(style))
        }
        
        switch self.type {
            // Document level
        case .Document:
            return content
            
            // Block level
        case .Heading(let level):
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.heading[level - 1].makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .UnorderedList:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.unorderedList.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .UnorderedListItem:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.unorderedListItem.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .OrderedList:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.orderedList.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .OrderedListItem(let index):
            let result = NSMutableAttributedString(string: "\n\n")

            let indexLabel = NSAttributedString(string: NSString(format: "%d. ", index) as String)
            result.insertAttributedString(indexLabel, atIndex: 1)
            result.insertAttributedString(content, atIndex: 1 + indexLabel.length)

            result.addAttributes(style.orderedListItem.makeAttributeDict(), range: NSMakeRange(0, result.length))

            // FIXME: do not convert list index types to arabic numbers
            return result
            
        case .CodeBlock:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.codeBlock.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .Paragraph:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.paragraph.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .Quote:
            let result = NSMutableAttributedString(string: "\n\n")
            result.insertAttributedString(content, atIndex: 1)
            result.addAttributes(style.quoteBlock.makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        // Inline
        // FIXME: Inline fonts are overridden by block level fonts, so bold, italic and code do not work correctly.
        case .PlainText:
            return NSAttributedString(string: self.text)
            
        case .StrongText:
            content.addAttributes(style.strongText.makeAttributeDict(), range: NSMakeRange(0, content.length))
            return content
            
        case .EmphasizedText:
            content.addAttributes(style.emphasizedText.makeAttributeDict(), range: NSMakeRange(0, content.length))
            return content
            
        case .DeletedText:
            content.addAttributes(style.deletedText.makeAttributeDict(), range: NSMakeRange(0, content.length))
            return content
            
        case .InlineCode:
            content.setAttributes(style.inlineCode.makeAttributeDict(), range: NSMakeRange(0, content.length))
            return content
            
        case .Link(let location):
            var attribs = style.strongText.makeAttributeDict()
            attribs[NSLinkAttributeName] = location
            content.addAttributes(attribs, range: NSMakeRange(0, content.length))
            return content
            
        case .Image:
            if style.embedImages {
                // TODO: Embed image
            }
            return NSAttributedString(string: "[\(content)]")
        }
    }
}
