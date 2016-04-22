//
//  ViewController.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 11/11/15.
//  Copyright © 2015 anfema GmbH. All rights reserved.
//

import UIKit
import html5tokenizer
import ion_client
import Markdown

@testable import ion_client

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let fontSize = CGFloat(10.0)
        var style = AttributedStringStyling(font: UIFont(name: "Helvetica", size: fontSize)!, strongFont: UIFont(name: "Helvetica-Bold", size: fontSize)!, emphasizedFont: UIFont(name: "Helvetica-Oblique", size: fontSize)!, baseColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())
        
        style.unorderedListItem.textIndent = 0
        style.orderedListItem.textIndent = 0

        let parser = HTMLParser(html:
            "<ul>" +
            "<li>List Element 1</li>" +
            "<li>List Element 2</li>" +
            "<li>List Element 3</li>" +
            "<li>List Element 4</li>" +
            "</ul>" +
            "<ul>" +
            "<li>List Element 1<ul>" +
            "<li>List Element 1.1</li>" +
            "<li>List Element 1.2</li>" +
            "<li>List Element 1.3</li>" +
            "<li>List Element 1.4</li>" +
            "</ul></li>" +
            "<li>List Element 2<ul>" +
            "<li>List Element 2.1</li>" +
            "<li>List Element 2.2</li>" +
            "<li>List Element 2.3</li>" +
            "<li>List Element 2.4</li>" +
            "</ul></li>" +
            "</ul>" +
            "<ol>" +
            "<li>List Element 1</li>" +
            "<li>List Element 2</li>" +
            "<li>List Element 3</li>" +
            "<li>List Element 4</li>" +
            "</ol>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<br>" +
            "<pre>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</pre>" +
            "<br>" +
            "<blockquote>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</blockquote>" +
            "<br>" +
            "<h1>Heading</h1>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<h2>Heading</h2>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<h3>Heading</h3>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<h4>Heading</h4>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<h5>Heading</h5>" +
            "<p>Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam</p>" +
            "<strong>strong</strong>" +
            "<br>" +
            "<del>deleted</del>" +
            "<br>" +
            "<a href=\"https://anfe.ma\">anfe.ma</a>" +
            "<br>" +
            "<b>bold</b>" +
            "<br>" +
            "<em>emphasized</em>" +
            "<br>" +
            "<i>italic</i>" +
            "<br>" +
            "<pre>pre</pre>" +
            "<br>" +
            "<code>code</code>" +
            "<p>Lorem <strong>strong</strong> ipsum dolor <a href=\"https://anfe.ma\">anfe.ma</a> sit <b>bold</b> amet, consetetur <br>" +
            "<pre>pre</pre>" + // FIXME: render error when included
            "<del>deleted</del>" + // FIXME: render error when included
            "<em>emphasized</em> sadipscing elitr, <i>italic</i> sed diam nonumy eirmod tem lore <code>code</code> magna aliquyam</p>"
        )
        
        self.textView.attributedText = parser.renderAttributedString(style)
        
        print(parser.renderText())
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

