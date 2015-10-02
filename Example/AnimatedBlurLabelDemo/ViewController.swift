//
//  ViewController.swift
//  AnimatedBlurLabelDemo
//
//  Created by Mathias Köhnke on 30/09/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var blurLabel : AnimatedBlurLabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByWordWrapping
        paragraph.alignment = .Center // potentially this can be an input param too, but i guess in most use cases we want center align
        
        blurLabel.attributedText = NSAttributedString(string: "This is a test", attributes: [NSParagraphStyleAttributeName : paragraph, NSFontAttributeName : UIFont.systemFontOfSize(32.0)])
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        blurLabel.setBlurred(false, animated: false) { finished in
            print("Finished!!!!")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

