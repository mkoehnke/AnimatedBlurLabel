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
        blurLabel.font = UIFont.boldSystemFontOfSize(48.0)
        blurLabel.text = "This is a test"
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        blurLabel.setBlurred(true, animated: true) { finished in
            print("Finished!!!!")
            self.blurLabel.font = UIFont.boldSystemFontOfSize(24.0)
            self.blurLabel.setBlurred(false, animated: true, completion: nil)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

