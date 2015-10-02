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
    private lazy var originalTextColor : UIColor? = {
       return self.textColor ?? .blackColor()
    }()
    
    override var textColor: UIColor! {
        didSet {
            if textColor != .clearColor() {
                self.originalTextColor = textColor
            }
        }
    }
    
    override var attributedText: NSAttributedString? {
        set(attributedText) {
            if let attributedText = attributedText where attributedText.length > 0 {
                super.attributedText = attributedText
                updateAttributesFromString()
                prepareImages()
            } else {
                super.attributedText = nil
            }
        }
        get {
            return super.attributedText
        }
    }
    
    override var text: String? {
        set(text) {
            if let text = text {
                self.attributedText = NSAttributedString(string: text, attributes: defaultAttributes())
            } else {
                self.attributedText = nil
            }
        }
        get {
            return self.attributedText?.string
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
            textColor = .clearColor()
            blurLayer1.contents = blurredImages[Int(blurredImages.count-1)].CGImage
            blurLayer2.contents = blurredImages[Int(blurredImages.count-1)].CGImage
        } else {
            blurLayer1.contents = nil
            blurLayer2.contents = nil
            textColor = originalTextColor
        }
    }
    
    private func callCompletion(completion: ((finished: Bool) -> Void)?, finished: Bool) {
        if let completion = completion {
            completion(finished: finished)
        }
        self.completionParameter = nil
        self.blurredParameter = nil
        self.animatedParameter = nil
        print("Finished blurring: \(finished)")
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
        blurLayer1.contents = blurredImages[blurIndex].CGImage
        blurLayer2.contents = blurredImages[blurIndex + 1].CGImage
        blurLayer2.opacity = Float(blurRemainder)
        CATransaction.setDisableActions(false)
        
        print("remainder: \(blurRemainder) - blurIndex: \(blurIndex + 1) - count: \(blurredImages.count)")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        layer.addSublayer(blurLayer1)
        layer.addSublayer(blurLayer2)
        
        self.textColor = originalTextColor
    }
    
    private func prepareImages() {
        if let attributedText = attributedText {
            blurredImagesReady = false
            let image = attributedText.imageFromText(bounds.size)
            imageToBlur = CIImage(image: image)
            blurredImages.append(image)
            blurredImages.append(image)
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { [weak self] in
                if let strongSelf = self {
                    for i in 1...strongSelf.numberOfStages {
                        let radius = Double(i) * Double(strongSelf.blurRadius) / Double(strongSelf.numberOfStages)
                        let blurredImage = strongSelf.applyBlurEffect(image, blurLevel: Double(radius))
                        strongSelf.blurredImages.append(blurredImage)
                        
//                        if i == strongSelf.numberOfStages {
//                            strongSelf.blurredImages.append(blurredImage)
//                        }
                    }
                    strongSelf.blurredImagesReady = true
                    
                    if let blurredParameter = strongSelf.blurredParameter,
                        animatedParameter = strongSelf.animatedParameter,
                        completionParameter = strongSelf.completionParameter {
                            dispatch_async(dispatch_get_main_queue(), { [weak self] in
                                self?.setBlurred(blurredParameter, animated: animatedParameter, completion: completionParameter)
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
        return [NSParagraphStyleAttributeName : paragraph, NSFontAttributeName : font, NSForegroundColorAttributeName : textColor]
    }
    
    private func updateAttributesFromString() {
        if let string = attributedText {
            string.enumerateAttribute(NSFontAttributeName, inRange: NSMakeRange(0, string.length), options: []) { [weak self] value, range, stop in
                self?.font = value as? UIFont
                stop.memory = true
            }
            
            string.enumerateAttribute(NSForegroundColorAttributeName, inRange: NSMakeRange(0, string.length), options: []) { [weak self] value, range, stop in
                self?.textColor = value as? UIColor
                stop.memory = true
            }
            
            string.enumerateAttribute(NSParagraphStyleAttributeName, inRange: NSMakeRange(0, string.length), options: []) { [weak self] value, range, stop in
                let paragraphStyle = value as? NSParagraphStyle
                if let alignment = paragraphStyle?.alignment {
                    self?.textAlignment = alignment
                }
                if let lineBreakMode = paragraphStyle?.lineBreakMode {
                    self?.lineBreakMode = lineBreakMode
                }
                stop.memory = true
            }
        }
    }
    
    deinit {
        displayLink!.removeFromRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
        displayLink = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        blurLayer1.bounds = bounds
        blurLayer1.position = center
        blurLayer2.bounds = bounds
        blurLayer2.position = center
    }

    private func applyBlurEffect(image: UIImage, blurLevel: Double) -> UIImage {
        blurfilter.setValue(blurLevel, forKey: kCIInputRadiusKey)
        blurfilter.setValue(imageToBlur, forKey: kCIInputImageKey)
        let resultImage = blurfilter.outputImage!
        
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