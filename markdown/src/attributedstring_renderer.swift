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

public enum RenderMode {
    case normal
    case excludeFont
    case fontOnly
}

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
    public var tabStops = [Float]()
    
    public func makeAttributeDict(nestingDepth: Int = 0, renderMode: RenderMode = .normal) -> Dictionary<String, Any> {
        var result = Dictionary<String, Any>()
        
        if let font = self.font, renderMode != .excludeFont {
            result[NSFontAttributeName] = font
        }
        
        if let foregroundColor = self.foregroundColor {
            result[NSForegroundColorAttributeName] = foregroundColor
        }
        if let backgroundColor = self.backgroundColor {
            result[NSBackgroundColorAttributeName] = backgroundColor
        }
        if let underline = self.underline {
            result[NSUnderlineStyleAttributeName] = (underline ? NSUnderlineStyle.styleSingle.rawValue : NSUnderlineStyle.styleNone.rawValue)
        }
        if let strikeThrough = self.strikeThrough {
            result[NSStrikethroughStyleAttributeName] = (strikeThrough ? NSUnderlineStyle.styleSingle.rawValue : NSUnderlineStyle.styleNone.rawValue)
        }
        
        if renderMode == .fontOnly {
            return result
        }
        
        var useParagraphStyle = false
        
        #if os(iOS)
        let paragraphStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        #else
        let paragraphStyle = NSParagraphStyle.default().mutableCopy() as! NSMutableParagraphStyle
        #endif
        
        
        if let alignment = self.alignment {
            useParagraphStyle = true
            paragraphStyle.alignment = alignment
        }
        
        if let textIndent = self.textIndent {
            useParagraphStyle = true
            paragraphStyle.firstLineHeadIndent = CGFloat(textIndent * (nestingDepth + 1))
            if textIndent == 0 {
                if self.tabStops.count > 0 {
                    paragraphStyle.headIndent = CGFloat(self.tabStops[0])
                }
            } else {
                paragraphStyle.headIndent = CGFloat(textIndent * (nestingDepth + 1)) + CGFloat(textIndent)
            }
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
        
        if self.tabStops.count > 0 {
            var align = self.alignment
            if align == nil {
                align = NSTextAlignment.left
            }
            var stops = [NSTextTab]()
            for stop in self.tabStops {
                stops.append(NSTextTab(textAlignment: align!, location: CGFloat(stop), options: [String:Any]()))
            }
            paragraphStyle.tabStops = stops
        }
        
        if useParagraphStyle {
            result[NSParagraphStyleAttributeName] = paragraphStyle
        }
        
        return result
    }
}

public struct AttributedStringStyling {
    public var heading:[AttributedStringStyle]
    public var unorderedList:AttributedStringStyle
    public var unorderedListItem:AttributedStringStyle
    public var orderedList:AttributedStringStyle
    public var orderedListItem:AttributedStringStyle
    public var codeBlock:AttributedStringStyle
    public var paragraph:AttributedStringStyle
    public var quoteBlock:AttributedStringStyle
    
    public var strongText:AttributedStringStyle
    public var emphasizedText:AttributedStringStyle
    public var deletedText:AttributedStringStyle
    public var inlineCode:AttributedStringStyle
    public var link:AttributedStringStyle
    
    public var embedImages:Bool
    
    public init() {
        #if os(iOS)
            self.init(font: UIFont.systemFont(ofSize: 17.0),
                strongFont: UIFont.boldSystemFont(ofSize: 17.0),
                emphasizedFont: UIFont.italicSystemFont(ofSize: 17.0),
                baseColor: UIColor.black,
                backgroundColor: UIColor.white)
        #else
            self.init(font: NSFont(name: "Helvetica", size: 16.0)!,
                strongFont: NSFont(name: "Helvetica-Bold", size: 16.0)!,
                emphasizedFont: NSFont(name: "Helvetica-Oblique", size: 16.0)!,
                baseColor: NSColor.black,
                backgroundColor: NSColor.white)
        #endif
    }
    
    public init(font: Font, strongFont: Font, emphasizedFont: Font, baseColor: Color, backgroundColor: Color) {
        let list = AttributedStringStyle()
        self.unorderedList = list
        self.orderedList = list
        
        var listItems = AttributedStringStyle()
        listItems.font = font
        listItems.foregroundColor = baseColor
        listItems.backgroundColor = backgroundColor
        listItems.textIndent = Int(font.pointSize)
        listItems.tabStops.append(2.0 * Float(font.pointSize))
        listItems.tabStops.append(3.0 * Float(font.pointSize))
        listItems.tabStops.append(4.0 * Float(font.pointSize))
        
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
        paragraph.marginBottom = Float(font.pointSize)
        self.paragraph = paragraph
        
        var quote = AttributedStringStyle()
        quote.textIndent = Int(font.pointSize)
        quote.font = font
        quote.foregroundColor = baseColor
        quote.backgroundColor = backgroundColor
        self.quoteBlock = quote
        
        var strong = AttributedStringStyle()
        strong.font = strongFont
        strong.foregroundColor = baseColor
        strong.backgroundColor = backgroundColor
        self.strongText = strong
        
        var em = AttributedStringStyle()
        em.font = emphasizedFont
        em.foregroundColor = baseColor
        em.backgroundColor = backgroundColor
        self.emphasizedText = em
        
        var delete = AttributedStringStyle()
        delete.font = font
        delete.strikeThrough = true
        delete.foregroundColor = baseColor
        delete.backgroundColor = backgroundColor
        self.deletedText = delete
        
        var inlineCode = AttributedStringStyle()
        inlineCode.font = codeBlock.font
        inlineCode.foregroundColor = baseColor
        inlineCode.backgroundColor = backgroundColor
        self.inlineCode = inlineCode
        
        var link = AttributedStringStyle()
        link.font = font
        link.underline = true
        #if os(iOS)
            link.foregroundColor = UIColor.blue
        #else
            link.foregroundColor = NSColor.blue
        #endif
        self.link = link
        
        self.embedImages = false
        
        self.heading = []
        self.calculateHeadingSizes(1.1, font: strongFont, baseColor: baseColor, backgroundColor: backgroundColor)
    }
    
    public mutating func calculateHeadingSizes(_ multiplier: Float, font: Font, baseColor: Color, backgroundColor: Color) {
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
            settings.marginTop = fontSize / 4.0
            settings.marginBottom = fontSize / 2.0
            settings.foregroundColor = baseColor
            settings.backgroundColor = backgroundColor

            self.heading.append(settings)
        }
    }
}

extension ContentNode {
    
    public func renderAttributedString(usingStyle style: AttributedStringStyling) -> NSAttributedString {
        let content = NSMutableAttributedString(string: "")
        for child in self.children {
            content.append(child.renderAttributedString(usingStyle: style))
        }
        
        switch self.type {
            // Document level
        case .document:
            return content
            
            // Block level
        case .heading(let level):
            let result = NSMutableAttributedString(string: "\n")
            result.insert(content, at: 0)
            result.addAttributes(style.heading[level - 1].makeAttributeDict(), range: NSMakeRange(0, result.length))
            return result
            
        case .unorderedList(let nestingDepth):
            let result = NSMutableAttributedString(string: "\n")
            result.insert(content, at: 0)
            result.addAttributes(style.unorderedList.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .excludeFont), range: NSMakeRange(0, result.length))
            return result
            
        case .unorderedListItem(let nestingDepth):
            let result = NSMutableAttributedString(string: "•\t\n")
            result.insert(content, at: 2)
            result.addAttributes(style.unorderedListItem.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, 2))
            var startIndex:Int? = nil
            // find first attribute with different indent
            result.enumerateAttribute(NSParagraphStyleAttributeName, in: NSMakeRange(2, result.length - 2), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) in
                if startIndex == nil {
                    startIndex = range.location
                }
            }
            if startIndex == nil {
                startIndex = result.length
            }
            result.addAttributes(style.unorderedListItem.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .excludeFont), range: NSMakeRange(0, startIndex!))
            return result
            
        case .orderedList(let nestingDepth):
            let result = NSMutableAttributedString(string: "\n")
            result.insert(content, at: 0)
            result.addAttributes(style.orderedList.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .excludeFont), range: NSMakeRange(0, result.length))
            return result
            
        case .orderedListItem(let index, let nestingDepth):
            let result = NSMutableAttributedString(string: "\n")
            
            let indexLabel = NSAttributedString(string: NSString(format: "%d.\t", index) as String)
            result.insert(indexLabel, at: 0)
            result.insert(content, at: indexLabel.length)
            result.addAttributes(style.unorderedListItem.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, indexLabel.length))
            
            var startIndex:Int? = nil
            // find first attribute with different indent
            result.enumerateAttribute(NSParagraphStyleAttributeName, in: NSMakeRange(indexLabel.length, result.length - indexLabel.length), options: NSAttributedString.EnumerationOptions(rawValue: 0)) { (value, range, stop) in
                if startIndex == nil && range.location > 0 {
                    startIndex = range.location
                }
            }
            if startIndex == nil {
                startIndex = result.length
            }
            result.addAttributes(style.orderedListItem.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .excludeFont), range: NSMakeRange(0, startIndex!))
            
            // FIXME: do not convert list index types to arabic numbers
            return result
            
        case .codeBlock(_, let nestingDepth):
            let result = NSMutableAttributedString(string: "\n\n")
            result.insert(content, at: 0)
            result.addAttributes(style.codeBlock.makeAttributeDict(nestingDepth: nestingDepth), range: NSMakeRange(0, result.length))
            return result
            
        case .paragraph(let nestingDepth):
            let result = NSMutableAttributedString(string: "\n\n")
            result.insert(content, at: 0)
            result.addAttributes(style.paragraph.makeAttributeDict(nestingDepth: nestingDepth, renderMode: .excludeFont), range: NSMakeRange(0, result.length))
            return result
            
        case .quote(let nestingDepth):
            let result = NSMutableAttributedString(string: "\n\n")
            result.insert(content, at: 1)
            result.addAttributes(style.quoteBlock.makeAttributeDict(nestingDepth: nestingDepth), range: NSMakeRange(0, result.length))
            return result
            
            // Inline
        case .plainText:
            let result = NSMutableAttributedString(string: self.text)
            result.addAttributes(style.paragraph.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, result.length))
            return result
            
        case .strongText:
            content.addAttributes(style.strongText.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, content.length))
            return content
            
        case .emphasizedText:
            content.addAttributes(style.emphasizedText.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, content.length))
            return content
            
        case .deletedText:
            content.addAttributes(style.deletedText.makeAttributeDict(), range: NSMakeRange(0, content.length))
            return content
            
        case .inlineCode:
            content.setAttributes(style.inlineCode.makeAttributeDict(renderMode: .fontOnly), range: NSMakeRange(0, content.length))
            return content
            
        case .link(let location):
            var attribs = style.strongText.makeAttributeDict()
            attribs[NSLinkAttributeName] = location
            content.addAttributes(attribs, range: NSMakeRange(0, content.length))
            return content
            
        case .image:
            if style.embedImages {
                // TODO: Embed image
            }
            return NSAttributedString(string: "[\(content)]")
        }
    }
}
