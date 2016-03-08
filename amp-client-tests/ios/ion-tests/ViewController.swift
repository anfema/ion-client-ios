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
        // Do any additional setup after loading the view, typically from a nib.
        
        let fontSize = CGFloat(10.0)
        var style = AttributedStringStyling(font: UIFont(name: "Helvetica", size: fontSize)!, strongFont: UIFont(name: "Helvetica-Bold", size: fontSize)!, emphasizedFont: UIFont(name: "Helvetica-Oblique", size: fontSize)!, baseColor: UIColor.blackColor(), backgroundColor: UIColor.whiteColor())
        
        style.unorderedListItem.textIndent = 0
        style.orderedListItem.textIndent = 0
        
//        let parser = HTMLParser(html:"<h1>Heading 1</h1>\n<h2>Heading 2</h2>\n\n<p> Text text text text\n\ntext text</p>\n<ul>\n<li>Item 1\n<ol>\n<li>Item 1</li>\n<li>Item 2</li>\n</ol>\n</li>\n<li>Item 2</li>\n</ul>\n\n\n<pre>Code\nblock\n</pre>\n\n<p><strong>Fancy</strong> <em>Text</em> und normal <a href='http://google.de'>weiter</a></p>")
//        let parser = HTMLParser(html:"<p><b>AUDI AG</b></p><p><b>AUDI AG Postanschrift:<br></b>AUDI AG<br>85045 Ingolstadt</p><p><b>Fachliche Verantwortung:<br></b>I/FP-2 IT-Strategie / Steuerung</p><p><b>Support:</b><br>Audi Service Desk<br>Telefon: +49 (0) 841-89-36565<br>E-Mail: 36565@audi.de</p><p>Die AUDI AG ist eine Aktiengesellschaft deutschen Rechts mit Hauptsitz in Ingolstadt.</p><p><b>Vorstand:</b><br>Rupert Stadler (Vorsitzender des Vorstands)<br>Ulrich Hackenberg<br>Bernd Martens<br>Thomas Siri<br>Axel Stortbak<br>Dietmar Roggenreiter<br>Hubert Waltl</p><p>Die AUDI AG ist im Handelsregister des Amtsgerichts Ingolstadt unter der Nummer HR B 1 eingetragen.</p><p>Die Umsatzsteueridentifikationsnummer der AUDI AG ist DE811115368.</p>")

//        let parser = HTMLParser(html:"<p>Wir führen die Fabrikkostenpotenziale aus laufenden Unternehmensaktivitäten in einer zentralen Registrierkasse zusammen. Hierzu gehören insbesondere folgende Initiativen: </p><ul><li>das frühzeitige Aufzeigen von Fabrikkosteneffekten im Produktentstehungsprozess sowie das Einsteuern von Maßnahmen zur Fabrikkostenoptimierung.</li><li>die Komplexitätsreduzierung in laufender Serie und im Produktentstehungsprozess.</li><li>die Optimierung der Beschaffungsnebenkosten der AUDI AG.</li><li>die kontinuierliche Produktivitätssteigerung in der Fertigung sowie den angrenzenden Bereichen.</li></ul><p>Verantwortlich:</p><ul><li>Jürgen Baur, I/PG-G<br></li><li>Thomas Bartl, I/PG-B<br></li><li>Michael Hauf, I/PL<br></li><li>alle Werkleiter<br></li></ul>")

        let parser = HTMLParser(html:"<ul><li>Aktivitäten der Standorte zur Optimierung der Fabrikkosten im eigenen Einflussbereich.</li><li>Rasche Umsetzung der Ideen am eigenen Standort.</li><li>Wissens- und Erfahrungsaustausch mit anderen Standorten zum Transfer der besten Maßnahmen.</li></ul><p>Verantwortlich:</p><ul><li>IN: Peter Demling, I/PI-5</li><li>NEC: Stefan Reich, N/PN-623</li><li>GY: Christian Bechheim, G/GG</li><li>BRX: Michel Pacolet, B/FC</li></ul>")

        self.textView.attributedText = parser.renderAttributedString(style)
//        self.textView.text = parser.renderText()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

