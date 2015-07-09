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
    @IBOutlet weak var button: UIButton!
    var circle:CAShapeLayer!
    var drawAnimation:CABasicAnimation!
    var networkManager:MDNetworkManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
        self.startAnimatingLoader()
        self.networkManager = MDNetworkManager()
        self.networkManager.connect()
        
        self.button.addTarget(self, action: "startCircleAnimation", forControlEvents: UIControlEvents.TouchDown)
        self.button.addTarget(self, action: "endCircleAnimation", forControlEvents: UIControlEvents.TouchUpInside)
        
        var longPress = UILongPressGestureRecognizer(target: self, action: "openDoor")
        longPress.minimumPressDuration = CFTimeInterval(1.2)
//        self.button.addGestureRecognizer(longPress)

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
    
        self.drawAnimation.fromValue = NSNumber(float: 0)
        self.drawAnimation.toValue   = NSNumber(float: 1)
        self.drawAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.drawAnimation.delegate = self
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
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if(flag){
            self.openDoor()
        }
    }
    
    func openDoor(){
        var json = Dictionary<String,AnyObject>()
        json["left"] = 1
        json["right"] = 2
        json["speed"] = 3
        json["direction"] = 4
        self.networkManager.sendAction(json)
        self.startAnimatingLoader()
    }

}

