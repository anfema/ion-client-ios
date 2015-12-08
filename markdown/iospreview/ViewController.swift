//
//  ViewController.swift
//  iospreview
//
//  Created by Johannes Schriewer on 11/11/15.
//  Copyright © 2015 anfema. All rights reserved.
//

import UIKit
import Markdown

class ViewController: UIViewController {
    @IBOutlet weak var markdownView: UITextView!
    @IBOutlet weak var renderedView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func convertMarkdown(sender: AnyObject) {
        let renderer = MDParser(markdown: markdownView.text)
        let dom = renderer.render()
        print(dom)
        let style = AttributedStringStyling(font: UIFont.systemFontOfSize(15), strongFont: UIFont.boldSystemFontOfSize(15), emphasizedFont: UIFont.italicSystemFontOfSize(15), baseColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())
        self.renderedView.attributedText = dom.renderAttributedString(style)
    }
}

