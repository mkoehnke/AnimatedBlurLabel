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
    @IBOutlet weak var blurButton : UIButton!
    @IBOutlet weak var unblurButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurLabel.animationDuration = 1.0
        blurLabel.setTitle("AnimatedBlurLabel", subtitle: "Subtitle", alignment: .Center)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("isBlurred: \(blurLabel.isBlurred)")
        setBlurEnabled(!blurLabel.isBlurred)
    }
    
    @IBAction func blurButtonTouched(sender: AnyObject) {
        setButtonEnabled(blurButton, enabled: false)
        setButtonEnabled(unblurButton, enabled: false)
        blurLabel.setBlurred(true, animated: true) { [weak self] finished in
            self?.setBlurEnabled(false)
        }
    }
    
    @IBAction func unblurButtonTouched(sender: AnyObject) {
        setButtonEnabled(blurButton, enabled: false)
        setButtonEnabled(unblurButton, enabled: false)
        blurLabel.setBlurred(false, animated: true) { [weak self] finished in
            self?.setBlurEnabled(true)
        }
        
    }
    
    func setBlurEnabled(enabled: Bool) {
        setButtonEnabled(blurButton, enabled: enabled)
        setButtonEnabled(unblurButton, enabled: !enabled)
    }
    
    func setButtonEnabled(button: UIButton, enabled: Bool) {
        button.enabled = enabled
        button.alpha = (enabled) ? 1.0 : 0.5
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
}

