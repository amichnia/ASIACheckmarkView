//
//  ASIACheckmarkView.swift
//  ASIACheckmarkView
//
//  Created by Andrzej Michnia on 13.03.2016.
//  Copyright © 2016 Andrzej Michnia Usługi Programistyczne. All rights reserved.
//

import UIKit

/// Default void completion block
public typealias ASIACompletion = ()->()

@IBDesignable
open class ASIACheckmarkView: UIButton {
    // MARK: - Inspectable Configuration
    /// Line color for checkmark checked
    @IBInspectable open var lineColorForTrue : UIColor = UIColor.green
    /// Line color for checkmark unchecked
    @IBInspectable open var lineColorForFalse : UIColor = UIColor.red
    /// Line width
    @IBInspectable open var lineWidth : CGFloat = 1
    /// CHeckmark fill, where 0 is no checkmark, and 1 is checkmark connected with surrounding circle
    @IBInspectable open var checkmarkFill : CGFloat = 0.8
    /// Fill of rect for false value - 0 means no rect, 1 means cross out of circle bounds
    @IBInspectable open var crossFill : CGFloat = 0.4
    /// Fill of the whole button rect - if 1, will try to cover whole area (cropped to center square).
    @IBInspectable open var rectFill : CGFloat = 0.5
    /// Checked for true, unchecked otherwise
    @IBInspectable open var isGood : Bool = true
    /// Determines if animation should pause and wait on "spinning" state
    @IBInspectable open var isSpinning : Bool = false
    /// How much circle percentage should spinner take in <0:1>
    @IBInspectable open var spinnerPercentage : CGFloat = 0.25
    /// Animation duration
    @IBInspectable open var animationTotalTime : TimeInterval = 0.5
    /// Spinning duration
    @IBInspectable open var spinningFullDuration : CFTimeInterval = 0.8
    
    // MARK: - Public properties
    /// True for checked, false otherwise
    open var boolValue : Bool {
        get { return self.isGood }
        set { self.isGood = newValue }
    }
    /// True for checked, false otherwise
    open var checked: Bool {
        get { return self.isGood }
        set { self.isGood = newValue }
    }
    /// True if animating spinning, false otherwise
    open var isAnimating : Bool { return self.animating }
    
    // MARK: - Private properties
    /// Animation end closure completion
    fileprivate var endAnimationCLosure : ASIACompletion?
    fileprivate var checkmarkGoodLayer : CAShapeLayer?
    fileprivate var checkmarkBadLayers = [CAShapeLayer]()
    fileprivate var checkmarkCircleLayer : CAShapeLayer?
    fileprivate var animating : Bool = false
    fileprivate let checkmarkEnd : CGFloat = 0.265
    fileprivate let startAngle : CGFloat = -CGFloat.pi/4
    
    fileprivate var animationFirstStep : TimeInterval {
        return self.animationTotalTime * TimeInterval(self.checkmarkEnd)
    }
    fileprivate var animationSeccondStep : TimeInterval {
        return self.animationTotalTime - self.animationFirstStep
    }
    
    // MARK: - Action
    /// Changes desired state (boolValue) to given state. If checkmark is not spinning - animates to spinner, and then to final state (only if state changed). If you set isSpinning, after calling this method, checkmark will wait on spinning state, until you set isSpinning to false.
    ///
    /// - Parameters:
    ///   - checked: Animate to state
    ///   - completion: Completion block (fired after new state is determined)
    open func animate(checked: Bool, withCompletion completion:ASIACompletion? = nil){
        animateMarkGood(checked, completion: completion)
    }
    
    // MARK: - Animations
    fileprivate func animateMarkGood(_ good: Bool, completion:ASIACompletion? = nil) {
        let oldValue = self.isGood
        self.isGood = good
        
        if oldValue && !self.isGood && !self.isSpinning && !self.animating{
            self.animating = true
            self.endAnimationCLosure = {
                self.animating = false
                completion?()
            }
            self.animateGoodIntoSpinner(){
                self.startSpinning()
            }
        }
        else if !oldValue && self.isGood && !self.isSpinning && !self.animating{
            self.animating = true
            self.endAnimationCLosure = {
                self.animating = false
                completion?()
            }
            self.animateBadIntoSpinner(){
                self.startSpinning()
            }
        }
    }
    
    fileprivate func animateGoodIntoSpinner(_ completion: ASIACompletion?) {
        self.checkmarkGoodLayer?.strokeStart = 1
        self.checkmarkGoodLayer?.strokeEnd = 1
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            self.animateCircleIntoSpinner(self.animationSeccondStep, completion: completion)
        }
        
        let animation = CABasicAnimation(keyPath: "strokeStart")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = self.animationFirstStep
        animation.timingFunction = CAMediaTimingFunction(name: "easeIn")
        
        let animation2 = CABasicAnimation(keyPath: "strokeEnd")
        animation2.fromValue = self.checkmarkFill
        animation2.toValue = 1
        animation2.duration = self.animationFirstStep * 0.5
        animation2.timingFunction = CAMediaTimingFunction(name: "easeIn")
        
        self.checkmarkGoodLayer?.add(animation, forKey: animation.keyPath)
        self.checkmarkGoodLayer?.add(animation2, forKey: animation2.keyPath)
        
        CATransaction.commit()
    }
    
    fileprivate func animateSpinnerIntoGood(_ completion: ASIACompletion?) {
        self.animateSpinnerIntoCircle(self.animationSeccondStep){
            self.checkmarkGoodLayer?.strokeStart = 0
            self.checkmarkGoodLayer?.strokeEnd = self.checkmarkFill
            
            CATransaction.begin()
            CATransaction.setCompletionBlock { () -> Void in
                completion?()
                self.endAnimationCLosure = nil
            }
            
            let animation = CABasicAnimation(keyPath: "strokeStart")
            animation.fromValue = 1
            animation.toValue = 0
            animation.duration = self.animationFirstStep
            animation.timingFunction = CAMediaTimingFunction(name: "easeOut")
            
            let animation2 = CABasicAnimation(keyPath: "strokeEnd")
            animation2.fromValue = 1
            animation2.toValue = self.checkmarkFill
            animation2.duration = self.animationFirstStep
            animation2.timingFunction = CAMediaTimingFunction(name: "easeOut")
            
            self.checkmarkGoodLayer?.add(animation, forKey: animation.keyPath)
            self.checkmarkGoodLayer?.add(animation2, forKey: animation2.keyPath)
            
            CATransaction.commit()
        }
    }
    
    fileprivate func animateCircleIntoSpinner(_ duration: TimeInterval, completion: ASIACompletion?) {
        self.checkmarkCircleLayer?.strokeStart = 1 - self.spinnerPercentage
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            completion?()
        }
        
        let animation = CABasicAnimation(keyPath: "strokeStart")
        animation.fromValue = 0
        animation.toValue = 1 - self.spinnerPercentage
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: "linear")
        
        self.checkmarkCircleLayer?.add(animation, forKey: animation.keyPath)
        
        CATransaction.commit()
    }
    
    fileprivate func animateBadIntoSpinner(_ completion: ASIACompletion?) {
        // Setup
        for checkmark in self.checkmarkBadLayers {
            checkmark.strokeEnd = 0
        }
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            self.animateCircleIntoSpinner(self.animationSeccondStep, completion: completion)
        }
        
        for i in 0..<self.checkmarkBadLayers.count {
            self.animateCheckmarkBadLayer(i, from: 1, to: 0, duration: self.animationFirstStep)
        }
        
        CATransaction.commit()
    }
    
    fileprivate func animateSpinnerIntoBad(_ completion: ASIACompletion?) {
        self.animateSpinnerIntoCircle(self.animationSeccondStep){
            // Setup
            for checkmark in self.checkmarkBadLayers {
                checkmark.strokeEnd = 1
            }
            
            CATransaction.begin()
            CATransaction.setCompletionBlock { () -> Void in
                completion?()
                self.endAnimationCLosure = nil
            }
            
            for i in 0..<self.checkmarkBadLayers.count {
                self.animateCheckmarkBadLayer(i, from: 0, to: 1, duration: self.animationFirstStep)
            }
            
            CATransaction.commit()
        }
    }
    
    fileprivate func startSpinning(){
        if self.isSpinning {
            CATransaction.begin()
            CATransaction.setCompletionBlock { () -> Void in
                self.startSpinning()
            }
            
            let animation = CABasicAnimation(keyPath: "transform.rotation.z")
            animation.toValue = 2 * CGFloat.NativeType.pi
            animation.duration = self.spinningFullDuration
            animation.isCumulative = true
            animation.isRemovedOnCompletion = false
            animation.timingFunction = CAMediaTimingFunction(name: "linear")
            
            self.checkmarkCircleLayer?.add(animation, forKey: animation.keyPath)
            
            CATransaction.commit()
        }
        else {
            self.endSpinning()
        }
    }
    
    fileprivate func endSpinning(){
        if self.isGood {
            self.animateSpinnerIntoGood(self.endAnimationCLosure)
        }
        else {
            self.animateSpinnerIntoBad(self.endAnimationCLosure)
        }
    }
    
    fileprivate func animateSpinnerIntoCircle(_ duration: TimeInterval, completion: ASIACompletion?) {
        
        self.checkmarkCircleLayer?.strokeStart = 0
        
        let fromColor = self.checkmarkCircleLayer?.strokeColor
        let toColor = self.isGood ? self.lineColorForTrue.cgColor : self.lineColorForFalse.cgColor
        self.checkmarkCircleLayer?.strokeColor = toColor
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { () -> Void in
            completion?()
        }
        
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.toValue = 2 * CGFloat.NativeType.pi
        rotation.duration = duration
        rotation.isCumulative = true
        rotation.isRemovedOnCompletion = false
        rotation.timingFunction = CAMediaTimingFunction(name: "linear")
        
        let animation = CABasicAnimation(keyPath: "strokeStart")
        animation.fromValue = 1 - self.spinnerPercentage
        animation.toValue = 0
        animation.duration = duration
        animation.timingFunction = CAMediaTimingFunction(name: "linear")
        
        let color = CABasicAnimation(keyPath: "strokeColor")
        color.fromValue = fromColor
        color.toValue = toColor
        color.duration = duration
        color.timingFunction = CAMediaTimingFunction(name: "linear")
        
        self.checkmarkCircleLayer?.add(animation, forKey: animation.keyPath)
        self.checkmarkCircleLayer?.add(rotation, forKey: rotation.keyPath)
        self.checkmarkCircleLayer?.add(color, forKey: color.keyPath)
        
        CATransaction.commit()
    }
    
    fileprivate func animateCheckmarkBadLayer(_ index: Int, from: CGFloat, to: CGFloat, duration: TimeInterval) {
        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = from
        anim.toValue = to
        anim.duration = duration
        self.checkmarkBadLayers[index].add(anim, forKey: anim.keyPath)
    }
    
    // MARK: - Lifecycle
    open override func awakeFromNib() {
        super.awakeFromNib()
        
        self.addLayersIfNeeded()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        self.addLayersIfNeeded()
    }
    
    // MARK: - Configuration
    fileprivate func addMarkGoodShapeLayer() {
        self.checkmarkGoodLayer?.removeFromSuperlayer()
        self.checkmarkGoodLayer = CAShapeLayer()
        self.checkmarkGoodLayer?.frame = self.bounds
        let pathFrame = self.bounds.insetBy(dx: self.lineWidth, dy: self.lineWidth)
        
        let radius = (min(pathFrame.width,pathFrame.height) / 2) * self.rectFill
        
        let path = UIBezierPath()
        var startPoint = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        startPoint.x -= radius / 1.5
        var midPoint = CGPoint(x: self.bounds.width/2 - radius/6, y: self.bounds.height/2)
        midPoint.y += radius / 2
        path.move(to: startPoint)
        path.addLine(to: midPoint)
        
        let halCircle : CGFloat = CGFloat(0)
        
        path.addArc(withCenter: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2), radius: radius, startAngle: startAngle, endAngle: startAngle + halCircle, clockwise: true)
        
        self.checkmarkGoodLayer?.path = path.cgPath
        self.checkmarkGoodLayer?.lineWidth = self.lineWidth
        self.checkmarkGoodLayer?.strokeColor = self.lineColorForTrue.cgColor
        self.checkmarkGoodLayer?.backgroundColor = UIColor.clear.cgColor
        self.checkmarkGoodLayer?.fillColor = UIColor.clear.cgColor
        self.checkmarkGoodLayer?.lineCap = kCALineCapRound
        self.checkmarkGoodLayer?.strokeEnd = self.checkmarkFill
        
        self.layer.addSublayer(self.checkmarkGoodLayer!)
    }
    
    fileprivate func addCheckmarkBadLayer(x: CGFloat, y: CGFloat) {
        
        let badShapeLayer = CAShapeLayer()
        badShapeLayer.frame = self.bounds
        let pathFrame = self.bounds.insetBy(dx: self.lineWidth, dy: self.lineWidth)
        
        let radius = (min(pathFrame.width,pathFrame.height) / 2 ) * self.crossFill * self.rectFill
        
        let path = UIBezierPath()
        
        let startPoint = CGPoint(x: self.bounds.width/2, y: self.bounds.height/2)
        path.move(to: startPoint)
        path.addLine(to: CGPoint(x: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2).x + radius * x, y: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2).y + radius * y))
        
        badShapeLayer.path = path.cgPath
        badShapeLayer.lineWidth = self.lineWidth
        badShapeLayer.strokeColor = self.lineColorForFalse.cgColor
        badShapeLayer.backgroundColor = UIColor.clear.cgColor
        badShapeLayer.fillColor = UIColor.clear.cgColor
        
        badShapeLayer.strokeStart = 0
        badShapeLayer.strokeEnd = 1
        badShapeLayer.lineCap = kCALineCapRound
        
        self.layer.addSublayer(badShapeLayer)
        self.checkmarkBadLayers.append(badShapeLayer)
    }
    
    fileprivate func addCheckmarkCircleLayer() {
        
        self.checkmarkCircleLayer?.removeFromSuperlayer()
        self.checkmarkCircleLayer = CAShapeLayer()
        self.checkmarkCircleLayer?.frame = self.bounds
        let pathFrame = self.bounds.insetBy(dx: self.lineWidth, dy: self.lineWidth)
        
        let radius = min(pathFrame.width,pathFrame.height) / 2 * self.rectFill
        let path = UIBezierPath()
        
        let halCircle : CGFloat = CGFloat.pi
        path.addArc(withCenter: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2), radius: radius, startAngle: startAngle, endAngle: startAngle + halCircle, clockwise: true)
        path.addArc(withCenter: CGPoint(x: self.bounds.width/2, y: self.bounds.height/2), radius: radius, startAngle: startAngle + halCircle, endAngle: startAngle, clockwise: true)
        
        self.checkmarkCircleLayer?.path = path.cgPath
        self.checkmarkCircleLayer?.lineWidth = self.lineWidth
        self.checkmarkCircleLayer?.strokeColor = self.lineColorForFalse.cgColor
        self.checkmarkCircleLayer?.backgroundColor = UIColor.clear.cgColor
        self.checkmarkCircleLayer?.fillColor = UIColor.clear.cgColor
        self.checkmarkCircleLayer?.lineCap = kCALineCapRound
        
        self.layer.addSublayer(self.checkmarkCircleLayer!)
    }
    
    fileprivate func addLayersIfNeeded(){
        if self.checkmarkGoodLayer == nil {
            self.addMarkGoodShapeLayer()
            self.checkmarkGoodLayer?.strokeStart = self.isGood ? 0 : 1
        }
        if self.checkmarkBadLayers.isEmpty {
            self.addCheckmarkBadLayer(x: -1,y: -1)
            self.addCheckmarkBadLayer(x: -1,y:  1)
            self.addCheckmarkBadLayer(x:  1,y: -1)
            self.addCheckmarkBadLayer(x:  1,y:  1)
            
            for layer in self.checkmarkBadLayers {
                layer.strokeEnd = self.isGood ? 0 : 1
            }
        }
        if self.checkmarkCircleLayer == nil {
            self.addCheckmarkCircleLayer()
            self.checkmarkCircleLayer?.strokeColor = self.isGood ? self.lineColorForTrue.cgColor : self.lineColorForFalse.cgColor
        }
    }
    
    // MARK: - Custom drawing
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.addLayersIfNeeded()
    }
    
}
