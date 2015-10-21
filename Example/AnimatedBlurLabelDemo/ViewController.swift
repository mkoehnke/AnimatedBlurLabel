//
// ViewController.swift
//
// Copyright (c) 2015 Mathias Koehnke (http://www.mathiaskoehnke.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var blurLabel : AnimatedBlurLabel!
    @IBOutlet weak var blurButton : UIButton!
    @IBOutlet weak var unblurButton : UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        blurLabel.animationDuration = 1.0
        blurLabel.setTitle("Animated\nBlurLabel", subtitle: "Demo", alignment: .Left)
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

