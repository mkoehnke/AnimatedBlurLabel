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
        blurLabel.animationDuration = 1.0
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        paragraph.alignment = .Center
        let attributes = [NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName : UIColor.whiteColor()]
        
        let string = NSMutableAttributedString(string: "Title\n\nSubtitle", attributes: attributes)
        string.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(48.0), range: NSMakeRange(0, 5))
        string.addAttribute(NSFontAttributeName, value: UIFont.systemFontOfSize(14.0), range: NSMakeRange(7, 7))
        blurLabel.attributedText = string
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        blurLabel.setBlurred(true, animated: true) { finished in
            self.blurLabel.setBlurred(false, animated: true) { finished in
                
            }
        }
    }

}

