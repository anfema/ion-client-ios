//
//  ViewController.swift
//  test
//
//  Created by Johannes Schriewer on 09.10.15.
//  Copyright © 2015 anfema. All rights reserved.
//

import UIKit
import ampclient

class ViewController: UIViewController {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        AMP.config.locale = "de_DE"
        AMP.config.serverURL = NSURL(string: "http://monaco.local:8000/client/v1/")
        
        AMP.login("admin@anfe.ma", password: "test") { success in
            guard success else {
                return
            }
            
            AMP.collection("test").page("page_001").outlet("Text") { outlet in
                if case let outlet as AMPTextContent = outlet {
                    let content = outlet.attributedString()
                    dispatch_async(dispatch_get_main_queue()) {
                        self.textView.attributedText = content
                        self.label.attributedText = content
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

