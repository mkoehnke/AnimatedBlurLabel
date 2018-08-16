//
// AnimatedBlurLabel.swift
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

/// The AnimatedBlurLabel class
open class AnimatedBlurLabel : UILabel {
    
    /// The duration of the blurring/unblurring animation in seconds
    open var animationDuration : TimeInterval = 10.0
    
    /// The maximum blur radius that is applied to the text
    open var blurRadius : CGFloat = 30.0
    
    /// Returns true if blur has been applied to the text
    open var isBlurred : Bool {
        return !CFEqual(blurLayer1.contents as CFTypeRef!, renderedTextImage?.cgImage)
    }

    /**
    Starts the blurring/unbluring of the text, either with animation or without.
    
    - parameter blurred:    Pass 'true' for blurring the text, 'false' false for unblurring.
    - parameter animated:   Pass 'true' for an animated blurring.
    - parameter completion: The completion handler that is called when the blurring/unblurring
                            animation has finished.
    */
    open func setBlurred(_ blurred: Bool, animated: Bool, completion: ((_ finished : Bool) -> Void)?) {
        if animated {
            if canRun() {
                setBlurred(!blurred)
                if reverse == blurred { blurredImages = blurredImages.reversed() }
                completionParameter = completion
                reverse = !blurred
                startDisplayLink()
            } else {
                deferBlur(blurred, animated: animated, completion: completion)
                prepareImages()
            }
        } else {
            setBlurred(blurred)
            callCompletion(completion, finished: true)
        }
    }
    
    //
    // MARK: Private
    //
    
    fileprivate lazy var blurLayer1 : CALayer = self.setupBlurLayer()
    fileprivate lazy var blurLayer2 : CALayer = self.setupBlurLayer()
    fileprivate var blurredImages = [UIImage]()
    fileprivate var blurredImagesReady : Bool = false
    fileprivate let numberOfStages = 10
    fileprivate var reverse : Bool = false
    
    fileprivate var blurredParameter : Bool?
    fileprivate var animatedParameter : Bool?
    fileprivate var completionParameter : ((_ finished: Bool) -> Void)?
    
    fileprivate var renderedTextImage : UIImage?
    fileprivate var blurredTextImage : UIImage?
    fileprivate var attributedTextToRender: NSAttributedString?
    fileprivate var textToRender: String?
    
    fileprivate var context : CIContext = {
        let eaglContext = EAGLContext(api: .openGLES2)
        let instance = CIContext(eaglContext: eaglContext!, options: [ kCIContextWorkingColorSpace : NSNull() ])
        return instance
    }()
    
    // MARK: Filters
    
    fileprivate lazy var clampFilter : CIFilter = {
        let transform = CGAffineTransform.identity
        let instance = CIFilter(name: "CIAffineClamp")!
        instance.setValue(NSValue(cgAffineTransform: transform), forKey: "inputTransform")
        return instance
    }()
    fileprivate lazy var blurFilter : CIFilter = {
        return CIFilter(name: "CIGaussianBlur")!
    }()
    fileprivate lazy var colorFilter : CIFilter = {
        let instance = CIFilter(name: "CIConstantColorGenerator")!
        instance.setValue(self.blendColor, forKey: kCIInputColorKey)
        return instance
    }()
    fileprivate lazy var blendFilter : CIFilter = {
        return CIFilter(name: "CISourceAtopCompositing")!
    }()
    fileprivate lazy var blendColor : CIColor = {
        return CIColor(color: self.backgroundColor ?? self.superview?.backgroundColor ?? .white)
    }()
    fileprivate lazy var inputBackgroundImage : CIImage = {
        return self.colorFilter.outputImage!
    }()
    
    fileprivate var startTime : CFTimeInterval?
    fileprivate var progress : TimeInterval = 0.0
    
    
    // MARK: Label Attributes
    
    override open var textColor: UIColor! {
        didSet {
            resetAttributes()
        }
    }
    
    override open var attributedText: NSAttributedString? {
        set(newValue) {
            attributedTextToRender = newValue
            textToRender = nil
            resetAttributes()
        }
        get {
            return attributedTextToRender
        }
    }
    
    override open var text: String? {
        set(newValue) {
            textToRender = newValue
            attributedTextToRender = nil
            resetAttributes()
        }
        get {
            return textToRender
        }
    }
    
    override open var textAlignment : NSTextAlignment {
        didSet {
            resetAttributes()
        }
    }
    
    override open var font : UIFont! {
        didSet {
            resetAttributes()
        }
    }
    
    override open var lineBreakMode : NSLineBreakMode {
        didSet {
            resetAttributes()
        }
    }
    

    // MARK: Setup
    
    override open func awakeFromNib() {
        super.awakeFromNib()
        
        layer.addSublayer(blurLayer1)
        layer.addSublayer(blurLayer2)
        
        super.text = nil
        super.textAlignment = .center
    }

    
    fileprivate func setupBlurLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = kCAGravityCenter
        layer.bounds = bounds
        layer.position = center
        layer.contentsScale = UIScreen.main.scale
        return layer
    }
    
    // MARK: Animation
    
    fileprivate lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: #selector(AnimatedBlurLabel.animateProgress(_:)))
        instance.isPaused = true
        instance.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return instance
    }()
    
    fileprivate func startDisplayLink() {
        if (displayLink?.isPaused == true) {
            progress = 0.0
            startTime = CACurrentMediaTime();
            displayLink?.isPaused = false
        }
    }
    
    fileprivate func stopDisplayLink() {
        displayLink?.isPaused = true
    }
    
    @objc fileprivate func animateProgress(_ displayLink : CADisplayLink) {
        if (progress > animationDuration) {
            stopDisplayLink()
            setBlurred(!reverse)
            callCompletion(completionParameter, finished: true)
            return
        }
        
        if let startTime = startTime {
            let elapsedTime = CACurrentMediaTime() - startTime
            updateAppearance(elapsedTime)
            self.startTime = CACurrentMediaTime();
        }
    }
    
    fileprivate func updateAppearance(_ elapsedTime : CFTimeInterval?) {
        progress += elapsedTime!
        
        let r = Double(progress / animationDuration)
        let blur = max(0, min(1, r)) * Double(numberOfStages)
        let blurIndex = Int(blur)
        let blurRemainder = blur - Double(blurIndex)
        
        CATransaction.setDisableActions(true)
        blurLayer1.contents = blurredImages[blurIndex + 1].cgImage
        blurLayer2.contents = blurredImages[blurIndex + 2].cgImage
        blurLayer2.opacity = Float(blurRemainder)
        CATransaction.setDisableActions(false)
    }
    
    deinit {
        displayLink!.remove(from: RunLoop.main, forMode: RunLoopMode.commonModes)
        displayLink = nil
    }
    
    
    // MARK: Layout
    
    override open var intrinsicContentSize : CGSize {
        if let renderedTextImage = renderedTextImage {
            return renderedTextImage.size
        }
        return CGSize.zero
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        if bounds.equalTo(blurLayer1.bounds) == false {
            resetAttributes()
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            blurLayer1.frame = bounds
            blurLayer2.frame = bounds
            
            // Text Alignment
            if let renderedTextImage = renderedTextImage , hasAlignment(.center) == false {
                var newX = (bounds.size.width - renderedTextImage.size.width) / 2
                newX = hasAlignment(.right) ? newX : (newX * -1)
                blurLayer1.frame = blurLayer1.frame.offsetBy(dx: newX, dy: 0)
                blurLayer2.frame = blurLayer2.frame.offsetBy(dx: newX, dy: 0)
            }
            
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
    }
    
    
    // MARK: Text Rendering
    
    fileprivate func resetAttributes() {
        blurredParameter = nil
        animatedParameter = nil
        completionParameter = nil
        
        var text : NSAttributedString?
        if let attributedTextToRender = attributedTextToRender {
            text = attributedTextToRender
        } else if let textToRender = textToRender {
            text = NSAttributedString(string: textToRender, attributes: defaultAttributes())
        }
        
        let maxWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.size.width
        let maxHeight = preferredMaxLayoutWidth > 0 ? UIScreen.main.bounds.size.height : bounds.size.height
        
        renderedTextImage = text?.imageFromText(CGSize(width: maxWidth, height: maxHeight))
        if let renderedTextImage = renderedTextImage {
            blurredTextImage = applyBlurEffect(CIImage(image: renderedTextImage)!, blurLevel: Double(blurRadius))
        }
        
        reverse = false
        setBlurred(false)
        
        blurredImagesReady = false
        
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }
    
    
    // MARK: Blurring
    
    fileprivate func prepareImages() {
        if let renderedTextImage = renderedTextImage {
            if TARGET_IPHONE_SIMULATOR == 1 {
                print("Note: AnimatedBlurLabel is running on the Simulator. " +
                      "Software rendering is used. This might take a few seconds ...")
            }
            
            blurredImagesReady = false
            blurredImages = [UIImage]()
            
            let imageToBlur = CIImage(image: renderedTextImage)!
            let blurredImage = applyBlurEffect(imageToBlur, blurLevel: 0)
            blurredImages.append(blurredImage)
            blurredImages.append(blurredImage)
            
            DispatchQueue.global().async { [weak self] in
                if let strongSelf = self {
                    for i in 1...strongSelf.numberOfStages {
                        let radius = Double(i) * Double(strongSelf.blurRadius) / Double(strongSelf.numberOfStages)
                        let blurredImage = strongSelf.applyBlurEffect(imageToBlur, blurLevel: Double(radius))
                        strongSelf.blurredImages.append(blurredImage)
                        
                        if i == strongSelf.numberOfStages {
                            strongSelf.blurredImages.append(blurredImage)
                        }
                    }
                    strongSelf.blurredImagesReady = true
                    
                    if let blurredParameter = strongSelf.blurredParameter,
                        let animatedParameter = strongSelf.animatedParameter {
                            DispatchQueue.main.async(execute: { [weak self] in
                                self?.setBlurred(blurredParameter, animated: animatedParameter, completion: self?.completionParameter)
                            })
                    }
                }
            }
        }
    }
    
    fileprivate func applyBlurEffect(_ image: CIImage, blurLevel: Double) -> UIImage {
        var resultImage : CIImage = image
        if blurLevel > 0 {
            clampFilter.setValue(image, forKey: kCIInputImageKey)
            let clampResult = clampFilter.outputImage!
            
            blurFilter.setValue(blurLevel, forKey: kCIInputRadiusKey)
            blurFilter.setValue(clampResult, forKey: kCIInputImageKey)
            resultImage = blurFilter.outputImage!
        }
        
        blendFilter.setValue(resultImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        let blendOutput = blendFilter.outputImage!
        
        let offset : CGFloat = CGFloat(blurLevel * 2)
        let cgImage = context.createCGImage(blendOutput, from: CGRect(x: -offset, y: -offset, width: image.extent.size.width + (offset*2), height: image.extent.size.height + (offset*2)))
        let result = UIImage(cgImage: cgImage!)
        return result
    }
    
    // MARK: Helper Methods
    
    fileprivate func defaultAttributes() -> [NSAttributedStringKey : Any]? {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = lineBreakMode
        paragraph.alignment = textAlignment
        return [.paragraphStyle : paragraph, .font : font, .foregroundColor : textColor, .ligature : NSNumber(value: 0 as Int), .kern : NSNumber(value: 0.0 as Float)]
    }
    
    fileprivate func hasAlignment(_ alignment: NSTextAlignment) -> Bool {
        var hasAlignment = false
        if let text = attributedTextToRender {
            text.enumerateAttribute(.paragraphStyle, in: NSMakeRange(0, text.length), options: [], using: { value, _ , stop in
                let paragraphStyle = value as? NSParagraphStyle
                hasAlignment = paragraphStyle?.alignment == alignment
                stop.pointee = true
            })
        } else if let _ = textToRender {
            hasAlignment = textAlignment == alignment
        }
        return hasAlignment
    }
    
    fileprivate func deferBlur(_ blurred: Bool, animated: Bool, completion: ((_ finished : Bool) -> Void)?) {
        print("Defer blurring ...")
        blurredParameter = blurred
        animatedParameter = animated
        completionParameter = completion
    }
    
    fileprivate func canRun() -> Bool {
        return blurredImagesReady && (completionParameter == nil || (completionParameter != nil && animatedParameter != nil && blurredParameter != nil))
    }
    
    fileprivate func setBlurred(_ blurred: Bool) {
        if blurred {
            blurLayer1.contents = blurredTextImage?.cgImage
            blurLayer2.contents = blurredTextImage?.cgImage
        } else {
            blurLayer1.contents = renderedTextImage?.cgImage
            blurLayer2.contents = renderedTextImage?.cgImage
        }
    }
    
    fileprivate func callCompletion(_ completion: ((_ finished: Bool) -> Void)?, finished: Bool) {
        self.blurredParameter = nil
        self.animatedParameter = nil
        if let completion = completion {
            self.completionParameter = nil
            completion(finished)
        }
    }
}



private extension NSAttributedString {
    func sizeToFit(_ maxSize: CGSize) -> CGSize {
        return boundingRect(with: maxSize, options:(NSStringDrawingOptions.usesLineFragmentOrigin), context:nil).size
    }
    
    func imageFromText(_ maxSize: CGSize) -> UIImage {
        let padding : CGFloat = 5
        let size = sizeToFit(maxSize)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: size.width + padding*2, height: size.height + padding*2), false , 0.0)
        self.draw(in: CGRect(x: padding, y: padding, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
