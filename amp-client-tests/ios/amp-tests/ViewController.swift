//
//  ViewController.swift
//  amp-tests
//
//  Created by Johannes Schriewer on 11/11/15.
//  Copyright © 2015 Johannes Schriewer. All rights reserved.
//

import UIKit
import html5parser
import amp_client
import Markdown

@testable import amp_client

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let parser = HTMLParser(html:"<h1>Heading 1</h1>\n<h2>Heading 2</h2>\n\n<p> Text text text text\n\ntext text</p>\n<ul>\n<li>Item 1\n<ol>\n<li>Item 1</li>\n<li>Item 2</li>\n</ol>\n</li>\n<li>Item 2</li>\n</ul>\n\n\n<pre>Code\nblock\n</pre>\n\n<p><strong>Fancy</strong> <em>Text</em> und normal <a href='http://google.de'>weiter</a></p>")
//        self.textView.attributedText = parser.renderAttributedString(AttributedStringStyling())
        self.textView.text = parser.renderText()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

