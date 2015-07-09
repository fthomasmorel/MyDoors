//
//  ViewController.swift
//  MyDoors
//
//  Created by Florent TM on 08/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var border: UIImageView!
    var circle:CAShapeLayer!
    var drawAnimation:CABasicAnimation!
    @IBOutlet weak var button: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
        self.startAnimatingLoader()
        
        // Target for touch down (hold down)
        self.button.addTarget(self, action: "startCircleAnimation", forControlEvents: UIControlEvents.TouchDown)
        // Target for release
        self.button.addTarget(self, action: "endCircleAnimation", forControlEvents: UIControlEvents.TouchUpInside)
        
        var longPress = UILongPressGestureRecognizer(target: self, action: "openDoor")
        longPress.minimumPressDuration = CFTimeInterval(1)
        self.button.addGestureRecognizer(longPress)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func initView(){
        var radius = CGFloat(62)
        self.circle = CAShapeLayer()
        var bezier:UIBezierPath = (UIBezierPath(roundedRect: (rect: CGRectMake(0, 0, 2*radius, 2*radius)), cornerRadius: radius))
        self.circle.path = bezier.CGPath
        var x = (CGRectGetMidX(self.button.frame)-radius)
        var y = (CGRectGetMidY(self.button.frame)-radius)
        self.circle.position = CGPointMake(x,y)
        self.circle.fillColor = UIColor.clearColor().CGColor;
        self.circle.strokeColor = UIColor.whiteColor().CGColor;
        self.circle.lineWidth = 5;
        self.circle.strokeEnd = 0.0;
        self.view.layer.addSublayer(self.circle);
        
    }

    func startAnimatingLoader(){
        border.hidden = false
        let fullRotation = CGFloat(M_PI * 2)
        let animation = CAKeyframeAnimation()
        animation.keyPath = "transform.rotation.z"
        animation.duration = 1.2
        animation.removedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.repeatCount = Float.infinity
        animation.values = [0, fullRotation/4, fullRotation/2, fullRotation*3/4, fullRotation]
        border.layer.addAnimation(animation, forKey: "rotate")
    }
    
    func stopAnimatingLoader(){
        border.layer.removeAllAnimations()
        border.hidden = true
    }
    
    func circleAnimation(){
    // Configure animation
        self.drawAnimation = CABasicAnimation(keyPath:"strokeEnd")
        self.drawAnimation.duration            = 1.0;
        self.drawAnimation.repeatCount         = 1.0; // Animate only once..
    
    
    // Animate from no part of the stroke being drawn to the entire stroke being drawn
        self.drawAnimation.fromValue = NSNumber(float: 0)
    
    // Set your to value to one to complete animation
        self.drawAnimation.toValue   = NSNumber(float: 1)
    
    // Experiment with timing to get the appearence to look the way you want
    self.drawAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
    
    // Add the animation to the circle
    self.circle.addAnimation(self.drawAnimation, forKey:"draw")
    }
    
    func startCircleAnimation(){
        self.stopAnimatingLoader()
        self.circleAnimation()
    }
    
    func endCircleAnimation(){
        self.circle.removeAllAnimations()
        self.circle.removeFromSuperlayer()
        self.initView()
        
        if(self.border.hidden){
            self.startAnimatingLoader()
        }
    }
    
    func pauseLayer(layer:CALayer){
        var pausedTime:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
    
    func resumeLayer(layer:CALayer){
        var pausedTime:CFTimeInterval = layer.timeOffset;
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        var timeSincePause:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer:nil) - pausedTime;
        layer.beginTime = timeSincePause;
    }
    
    func openDoor(){
        self.button.setTitle("Fermer", forState: UIControlState.Normal)
        self.startAnimatingLoader()
    }

}

