//
//  ViewController.swift
//  MyDoors
//
//  Created by Florent TM on 08/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import UIKit
import QRCodeReader

class ViewController: UIViewController, MDNetworkManagerDelegate {

    //MARK: Attributes
    
    @IBOutlet weak var border: UIImageView!
    @IBOutlet weak var button: UIButton!
    
    let reader = QRCodeReaderViewController()
    
    var circle:CAShapeLayer!
    var drawAnimation:CABasicAnimation!
    var networkManager:MDNetworkManager!
    
    
    //MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.initView()
        self.startAnimatingLoader()
        
        NSUserDefaults.standardUserDefaults().setObject("$2bG67de92!y", forKey: kAuthKey)
        
        self.networkManager = MDNetworkManager()
        self.networkManager.delegate = self
        self.networkManager.connect()
        
        self.button.addTarget(self, action: "startCircleAnimation", forControlEvents: UIControlEvents.TouchDown)
        self.button.addTarget(self, action: "endCircleAnimation", forControlEvents: UIControlEvents.TouchUpInside)
    }
    
    override func viewDidAppear(animated: Bool) {
/*        if !((NSUserDefaults.standardUserDefaults().objectForKey(kAuthKey)) != nil) {
            self.presentViewController(reader, animated: true, completion: nil)
        }*/
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        if(flag){
            self.openDoor()
        }
    }
    
    
    //MARK: Animation
    
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
        self.drawAnimation = CABasicAnimation(keyPath:"strokeEnd")
        self.drawAnimation.duration            = 1.0;
        self.drawAnimation.repeatCount         = 1.0;
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
    
    
    //MARK: Action
    
    func openDoor(){
        self.networkManager.sendAction()
        self.startAnimatingLoader()
    }
    
    
    //MARK: MDNetworkManagerDelegate methods
    
    func didConnect(){
        
    }
    
    func didFailConnected(error:String){
        print(error)
    }
    
    func didReceivedData(json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            var title = (isOpen ? "Fermer" : "Ouvrir")
            self.button.setTitle(title, forState: .Normal)
        }
    }
    
    func didReceivedState(json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            var title = (isOpen ? "Fermer" : "Ouvrir")
            self.button.setTitle(title, forState: .Normal)
        }
    }

}

