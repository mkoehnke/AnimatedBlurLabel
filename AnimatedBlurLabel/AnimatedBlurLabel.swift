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
    
    func setBlurred(blurred: Bool, animated: Bool, completion: ((finished : Bool) -> Void)?) {
        if blurredImagesReady == false {
            deferBlur(blurred, animated: animated, completion: completion)
            prepareImages()
            return
        }
        
        if canRun() {
            print("Start blurring ...")
            if animated {
                setBlurred(!blurred)
                if reverse == blurred { blurredImages = blurredImages.reverse() }
                completionParameter = completion
                reverse = !blurred
                progress = 0.0
                startDisplayLink()
            } else {
                setBlurred(blurred)
                callCompletion(completion, finished: true)
            }
        } else {
            callCompletion(completion, finished: false)
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
    private var attributedTextToRender: NSAttributedString?
    private var textToRender: String?
    
    private var imageToBlur : CIImage?
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
    
    override var textColor: UIColor! {
        didSet {
            applyAttributesFromAttributedString()
        }
    }
    
    override var attributedText: NSAttributedString? {
        set(newValue) {
            attributedTextToRender = newValue
            textToRender = nil
            applyAttributesFromAttributedString()
        }
        get {
            return attributedTextToRender
        }
    }
    
    override var text: String? {
        set(newValue) {
            textToRender = newValue
            attributedTextToRender = nil
            applyAttributesFromAttributedString()
        }
        get {
            return textToRender
        }
    }
    
    override var textAlignment : NSTextAlignment {
        didSet {
            applyAttributesFromAttributedString()
        }
    }
    
    override var font : UIFont! {
        didSet {
            applyAttributesFromAttributedString()
        }
    }
    
    override var lineBreakMode : NSLineBreakMode {
        didSet {
            applyAttributesFromAttributedString()
        }
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
            blurLayer1.contents = blurredImages[Int(blurredImages.count-1)].CGImage
            blurLayer2.contents = blurredImages[Int(blurredImages.count-1)].CGImage
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
    
    private func setupBlurLayer() -> CALayer {
        let layer = CALayer()
        layer.contentsGravity = kCAGravityCenter
        layer.bounds = bounds
        layer.position = center
        layer.contentsScale = UIScreen.mainScreen().scale
        return layer
    }
    
    private lazy var displayLink : CADisplayLink? = {
        var instance = CADisplayLink(target: self, selector: Selector("animateProgress:"))
        instance.paused = true
        instance.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        return instance
    }()
    
    private func startDisplayLink() {
        if (progress < animationDuration && displayLink?.paused == true) {
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
        
        let elapsedTime = CACurrentMediaTime() - startTime!
        updateAppearance(elapsedTime)
        startTime = CACurrentMediaTime();
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
    
    override func awakeFromNib() {
        super.awakeFromNib()

        layer.addSublayer(blurLayer1)
        layer.addSublayer(blurLayer2)

        super.text = nil
        super.textAlignment = .Center
    }
    
    override func intrinsicContentSize() -> CGSize {
        if let renderedTextImage = renderedTextImage {
            return renderedTextImage.size
        }
        return CGSizeZero
    }
    
    private func prepareImages() {
        if let renderedTextImage = renderedTextImage {
            blurredImagesReady = false
            blurredImages = [UIImage]()
            imageToBlur = CIImage(image: renderedTextImage)
            
            let blurredImage = applyBlurEffect(renderedTextImage, blurLevel: 0)
            blurredImages.append(blurredImage)
            blurredImages.append(blurredImage)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
                if let strongSelf = self {
                    for i in 1...strongSelf.numberOfStages {
                        let radius = Double(i) * Double(strongSelf.blurRadius) / Double(strongSelf.numberOfStages)
                        let blurredImage = strongSelf.applyBlurEffect(renderedTextImage, blurLevel: Double(radius))
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
    
    private func defaultAttributes() -> [String : AnyObject]? {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = lineBreakMode
        paragraph.alignment = textAlignment
        return [NSParagraphStyleAttributeName : paragraph, NSFontAttributeName : font, NSForegroundColorAttributeName : textColor, NSLigatureAttributeName : NSNumber(integer: 0), NSKernAttributeName : NSNumber(float: 0.0)]
    }
    
    private func applyAttributesFromAttributedString() {
        var text : NSAttributedString?
        if let attributedTextToRender = attributedTextToRender {
            text = attributedTextToRender
        } else if let textToRender = textToRender {
            text = NSAttributedString(string: textToRender, attributes: defaultAttributes())
        }
        
        let maxWidth = preferredMaxLayoutWidth > 0 ? preferredMaxLayoutWidth : bounds.size.width
        let maxHeight = preferredMaxLayoutWidth > 0 ? UIScreen.mainScreen().bounds.size.height : bounds.size.height
        
        renderedTextImage = text?.imageFromText(CGSizeMake(maxWidth, maxHeight))
        blurLayer1.contents = renderedTextImage?.CGImage
        blurLayer2.contents = renderedTextImage?.CGImage
        blurredImagesReady = false
        
        invalidateIntrinsicContentSize()
        layoutIfNeeded()
    }
    
    deinit {
        displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        blurLayer1.frame = bounds
        blurLayer2.frame = bounds
        CATransaction.setDisableActions(false)
        CATransaction.commit()
    }

    private func applyBlurEffect(image: UIImage, blurLevel: Double) -> UIImage {
        let resultImage : CIImage!
        if blurLevel > 0 {
            blurfilter.setValue(blurLevel, forKey: kCIInputRadiusKey)
            blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
            resultImage = blurfilter.outputImage!
        } else {
            resultImage = CIImage(image: image)
        }

        blendFilter.setValue(resultImage, forKey: kCIInputImageKey)
        blendFilter.setValue(inputBackgroundImage, forKey: kCIInputBackgroundImageKey)
        let blendOutput = blendFilter.outputImage!
        
        let cgImage = context.createCGImage(blendOutput, fromRect: resultImage.extent)
        let result = UIImage(CGImage: cgImage, scale: image.scale, orientation: UIImageOrientation.Up)
        return result
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