//
//  UIKitExtensions.swift
//  AnimatedBlurLabelDemo
//
//  Created by Mathias Köhnke on 13/10/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import UIKit

extension UILabel {
    
    func setTitle(title: String?, subtitle: String?, alignment: NSTextAlignment = .Center) {
        if let title = title, subtitle = subtitle {
            let paragraph = NSMutableParagraphStyle()
            paragraph.lineBreakMode = NSLineBreakMode.ByTruncatingTail
            paragraph.alignment = alignment
            let attributes = [NSParagraphStyleAttributeName : paragraph, NSForegroundColorAttributeName : textColor, NSFontAttributeName : UIFont.systemFontOfSize(14.0)]
            
            let string = NSMutableAttributedString(string: "\(title)\n\n\(subtitle)", attributes: attributes)
            string.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFontOfSize(48.0), range: NSMakeRange(0, title.characters.count))
            
            attributedText = string
        }
    }
    
}
