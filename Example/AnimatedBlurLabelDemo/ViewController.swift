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
        blurLabel.setTitle("AnimatedBlurLabel", subtitle: "Subtitle", alignment: .Center)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        blurLabel.setBlurred(true, animated: true) { finished in
            self.blurLabel.setBlurred(false, animated: true) { finished in
                
            }
        }
    }

}

