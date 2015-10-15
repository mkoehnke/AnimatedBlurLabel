//
//  AnimatedBlurLabel.swift
//  AnimatedTextBlurDemo
//
//  Created by Mathias Köhnke on 30/09/15.
//  Copyright © 2015 Mathias Köhnke. All rights reserved.
//

import UIKit


class AnimatedBlurLabel : UILabel {
    
    var animationDuration : NSTimeInterval = 10.0
    var blurRadius : CGFloat = 30.0
    var isBlurred : Bool {
        return !CFEqual(blurLayer1.contents, renderedTextImage?.CGImage)
    }

    func setBlurred(blurred: Bool, animated: Bool, completion: ((finished : Bool) -> Void)?) {
        if animated {
            if canRun() {
                print("Start blurring ...")
                setBlurred(!blurred)
                if reverse == blurred { blurredImages = blurredImages.reverse() }
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
    
    private lazy var blurLayer1 : CALayer = self.setupBlurLayer()
    private lazy var blurLayer2 : CALayer = self.setupBlurLayer()
    private var blurredImages = [UIImage]()
    private var blurredImagesReady : Bool = false
    private let numberOfStages = 10
    private var reverse : Bool = false
    
    private var blurredParameter : Bool?
    private var animatedParameter : Bool?
    private var completionParameter : ((finished: Bool) -> Void)?
    
    private var renderedTextImage : UIImage?
    private var blurredTextImage : UIImage?
    private var attributedTextToRender: NSAttributedString?
    private var textToRender: String?
    
    private var context : CIContext = {
        let eaglContext = EAGLContext(API: .OpenGLES2)
        let instance = CIContext(EAGLContext: eaglContext, options: [ kCIContextWorkingColorSpace : NSNull() ])
        return instance
    }()
    
    private lazy var blurfilter : CIFilter = {
        return CIFilter(name: "CIGaussianBlur")!
    }()
    private lazy var colorFilter : CIFilter = {
        let instance = CIFilter(name: "CIConstantColorGenerator")!
        instance.setValue(self.blendColor, forKey: kCIInputColorKey)
        return instance
    }()
    private lazy var blendFilter : CIFilter = {
        return CIFilter(name: "CISourceAtopCompositing")!
    }()
    private lazy var blendColor : CIColor = {
        return CIColor(color: self.backgroundColor ?? self.superview?.backgroundColor ?? .whiteColor())
    }()
    private lazy var inputBackgroundImage : CIImage = {
        return self.colorFilter.outputImage!
    }()
    
    private var startTime : CFTimeInterval?
    private var progress : NSTimeInterval = 0.0
    
    
    // MARK: Label Attributes
    
    override var textColor: UIColor! {
        didSet {
            resetAttributes()
        }
    }
    
    override var attributedText: NSAttributedString? {
        set(newValue) {
            attributedTextToRender = newValue
            textToRender = nil
            resetAttributes()
        }
        get {
            return attributedTextToRender
        }
    }
    
    override var text: String? {
        set(newValue) {
            textToRender = newValue
            attributedTextToRender = nil
            resetAttributes()
        }
        get {
            return textToRender
        }
    }
    
    override var textAlignment : NSTextAlignment {
        didSet {
            resetAttributes()
        }
    }
    
    override var font : UIFont! {
        didSet {
            resetAttributes()
        }
    }
    
    override var lineBreakMode : NSLineBreakMode {
        didSet {
            resetAttributes()
        }
    }
    

    // MARK: Setup
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        layer.addSublayer(blurLayer1)
        layer.addSublayer(blurLayer2)
        
        super.text = nil
        super.textAlignment = .Center
    }

    
    private func setupBlurLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = kCAGravityCenter
        layer.bounds = bounds
        layer.position = center
        layer.contentsScale = UIScreen.mainScreen().scale
        return layer
    }
    
    // MARK: Animation
    
    private lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: Selector("animateProgress:"))
        instance.paused = true
        instance.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        return instance
    }()
    
    private func startDisplayLink() {
        if (displayLink?.paused == true) {
            progress = 0.0
            startTime = CACurrentMediaTime();
            displayLink?.paused = false
        }
    }
    
    private func stopDisplayLink() {
        displayLink?.paused = true
    }
    
    @objc private func animateProgress(displayLink : CADisplayLink) {
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
    
    private func updateAppearance(elapsedTime : CFTimeInterval?) {
        progress += elapsedTime!
        
        let r = Double(progress / animationDuration)
        let blur = max(0, min(1, r)) * Double(numberOfStages)
        let blurIndex = Int(blur)
        let blurRemainder = blur - Double(blurIndex)
        
        CATransaction.setDisableActions(true)
        blurLayer1.contents = blurredImages[blurIndex + 1].CGImage
        blurLayer2.contents = blurredImages[blurIndex + 2].CGImage
        blurLayer2.opacity = Float(blurRemainder)
        CATransaction.setDisableActions(false)
    }
    
    deinit {
        displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink = nil
    }
    
    
    // MARK: Layout
    
    override func intrinsicContentSize() -> CGSize {
        if let renderedTextImage = renderedTextImage {
            return renderedTextImage.size
        }
        return CGSizeZero
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if CGRectEqualToRect(bounds, blurLayer1.bounds) == false {
            resetAttributes()
            
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            blurLayer1.frame = bounds
            blurLayer2.frame = bounds
            
            // Text Alignment
            if let renderedTextImage = renderedTextImage where hasAlignment(.Center) == false {
                var newX = (bounds.size.width - renderedTextImage.size.width) / 2
                newX = hasAlignment(.Right) ? newX : (newX * -1)
                blurLayer1.frame = CGRectOffset(blurLayer1.frame, newX, 0)
                blurLayer2.frame = CGRectOffset(blurLayer2.frame, newX, 0)
            }
            
            CATransaction.setDisableActions(false)
            CATransaction.commit()
        }
    }
    
    
    // MARK: Text Rendering
    
    private func resetAttributes() {
        print("Rerendering Text ...")
        
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
        let maxHeight = preferredMaxLayoutWidth > 0 ? UIScreen.mainScreen().bounds.size.height : bounds.size.height
        
        renderedTextImage = text?.imageFromText(CGSizeMake(maxWidth, maxHeight))
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
    
    private func prepareImages() {
        if let renderedTextImage = renderedTextImage {
            blurredImagesReady = false
            blurredImages = [UIImage]()
            
            let imageToBlur = CIImage(image: renderedTextImage)!
            let blurredImage = applyBlurEffect(imageToBlur, blurLevel: 0)
            blurredImages.append(blurredImage)
            blurredImages.append(blurredImage)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
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
                        animatedParameter = strongSelf.animatedParameter {
                            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                                self?.setBlurred(blurredParameter, animated: animatedParameter, completion: self?.completionParameter)
                            })
                    }
                }
            }
        }
    }
    
    private func applyBlurEffect(image: CIImage, blurLevel: Double) -> UIImage {
        var resultImage : CIImage = image
        if blurLevel > 0 {
            blurfilter.setValue(blurLevel, forKey: kCIInputRadiusKey)
            blurfilter.setValue(image, forKey: kCIInputImageKey)
            resultImage = blurfilter.outputImage!
        }
        
        blendFilter.setValue(resultImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        let blendOutput = blendFilter.outputImage!
        
        let cgImage = context.createCGImage(blendOutput, fromRect: resultImage.extent)
        let result = UIImage(CGImage: cgImage)
        return result
    }
    
    // MARK: Helper Methods
    
    private func defaultAttributes() -> [String : AnyObject]? {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = lineBreakMode
        paragraph.alignment = textAlignment
        return [NSParagraphStyleAttributeName : paragraph, NSFontAttributeName : font, NSForegroundColorAttributeName : textColor, NSLigatureAttributeName : NSNumber(integer: 0), NSKernAttributeName : NSNumber(float: 0.0)]
    }
    
    private func hasAlignment(alignment: NSTextAlignment) -> Bool {
        var hasAlignment = false
        if let text = attributedTextToRender {
            text.enumerateAttribute(NSParagraphStyleAttributeName, inRange: NSMakeRange(0, text.length), options: [], usingBlock: { value, _ , stop in
                let paragraphStyle = value as? NSParagraphStyle
                hasAlignment = paragraphStyle?.alignment == alignment
                stop.memory = true
            })
        } else if let _ = textToRender {
            hasAlignment = textAlignment == alignment
        }
        return hasAlignment
    }
    
    private func deferBlur(blurred: Bool, animated: Bool, completion: ((finished : Bool) -> Void)?) {
        print("Defer blurring ...")
        blurredParameter = blurred
        animatedParameter = animated
        completionParameter = completion
    }
    
    private func canRun() -> Bool {
        return blurredImagesReady && (completionParameter == nil || (completionParameter != nil && animatedParameter != nil && blurredParameter != nil))
    }
    
    private func setBlurred(blurred: Bool) {
        if blurred {
            blurLayer1.contents = blurredTextImage?.CGImage
            blurLayer2.contents = blurredTextImage?.CGImage
        } else {
            blurLayer1.contents = renderedTextImage?.CGImage
            blurLayer2.contents = renderedTextImage?.CGImage
        }
    }
    
    private func callCompletion(completion: ((finished: Bool) -> Void)?, finished: Bool) {
        print("Finished blurring: \(finished)")
        self.blurredParameter = nil
        self.animatedParameter = nil
        if let completion = completion {
            self.completionParameter = nil
            completion(finished: finished)
        }
    }
}



private extension NSAttributedString {
    private func sizeOfAttributeString(str: NSAttributedString, maxSize: CGSize) -> CGSize {
        let size = str.boundingRectWithSize(maxSize, options:(NSStringDrawingOptions.UsesLineFragmentOrigin), context:nil).size
        return size
    }
    
    private func imageFromText(maxSize: CGSize) -> UIImage {
        let size = sizeOfAttributeString(self, maxSize:maxSize)
        UIGraphicsBeginImageContextWithOptions(size, false , 0.0)
        self.drawInRect(CGRectMake(0, 0, size.width, size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}