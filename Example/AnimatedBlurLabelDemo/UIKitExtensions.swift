//
// UIKitExtensions.swift
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

extension UILabel {
    
    func setTitle(_ title: String?, subtitle: String?, alignment: NSTextAlignment = .center) {
        if let title = title, let subtitle = subtitle {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = NSLineBreakMode.byWordWrapping
            paragraph.alignment = alignment
            paragraph.lineSpacing = 1.6;
            paragraph.lineHeightMultiple = 0.95;
            
            let attributes: [NSAttributedStringKey: Any] = [.paragraphStyle : paragraph, .foregroundColor : textColor, .font : UIFont.systemFont(ofSize: 33.0, weight: .thin)];
            
            let string = NSMutableAttributedString(string: "\(title)\n\(subtitle)", attributes: attributes)
            string.addAttribute(.font, value: UIFont.systemFont(ofSize: 42.0, weight: .bold), range: NSMakeRange(0, title.count))
            
            attributedText = string
        }
    }
    
}
