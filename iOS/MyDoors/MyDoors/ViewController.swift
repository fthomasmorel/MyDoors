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
    
    @IBOutlet weak var panel: UIView!
    @IBOutlet weak var border: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var updateLabel: UILabel!
    
    let reader = QRCodeReaderViewController()
    
    var circle:CAShapeLayer!
    var drawAnimation:CABasicAnimation!
    var networkManager:MDNetworkManager!
    
    
    //MARK: Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initQRReader()
        self.button.addTarget(self, action: "startCircleAnimation", forControlEvents: UIControlEvents.TouchDown)
        self.button.addTarget(self, action: "endCircleAnimation", forControlEvents: UIControlEvents.TouchUpInside)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        if !((NSUserDefaults.standardUserDefaults().objectForKey(kAuthKey)) != nil) {
            self.presentViewController(reader, animated: true) { () -> Void in
                
                let filter = UIImageView(frame: self.reader.view.frame)
                filter.image = UIImage(named: "filter")
                filter.contentMode = UIViewContentMode.ScaleToFill
                
                self.reader.view.addSubview(filter)
            }
        }else{
            self.networkManager = MDNetworkManager(withDelegate: self)
//            self.networkManager.connect()
        }
        
        self.initView()
        self.startAnimatingLoader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
        if(flag){
            self.openDoor()
        }
    }
    
    //MARK : Private
    
    private func updateLabelText(){
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: today)
        let hour = String(format: "%02d", components.hour)
        let minutes = String(format: "%02d", components.minute)
        updateLabel.text = "last update : \(hour):\(minutes)"
    }
    
    //MARK: QRReader
    
    func initQRReader(){
        reader.resultCallback = {
            print($1)
            do{
                let data = ($1).dataUsingEncoding(NSUTF8StringEncoding)!
                if let res: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions()) {
                    if let json = res as? NSDictionary, let id = json[kId] as? NSString{
                        if id == "com.thomasmorel.florent.MyDoors" {
                            NSUserDefaults.standardUserDefaults().setObject(json[kLocalHost], forKey: kLocalHost)
                            NSUserDefaults.standardUserDefaults().setObject(json[kRemoteHost], forKey: kRemoteHost)
                            NSUserDefaults.standardUserDefaults().setObject(json[kAuthKey], forKey: kAuthKey)
                        }
                    }
                }
            }catch let error{
                print(error)
            }
            $0.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    
    //MARK: Animation
    
    func initView(){
        let radius = CGFloat(62)
        self.circle = CAShapeLayer()
        let bezier:UIBezierPath = (UIBezierPath(roundedRect: (rect: CGRectMake(0, 0, 2*radius, 2*radius)), cornerRadius: radius))
        self.circle.path = bezier.CGPath
        let x = (CGRectGetMidX(self.button.frame)-radius)
        let y = (CGRectGetMidY(self.button.frame)-radius) + self.panel.frame.origin.y
        self.circle.position = CGPointMake(x,y)
        self.circle.fillColor = UIColor.clearColor().CGColor;
        self.circle.strokeColor = self.button.titleLabel?.textColor.CGColor;
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
        let pausedTime:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer: nil)
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
    
    func resumeLayer(layer:CALayer){
        let pausedTime:CFTimeInterval = layer.timeOffset;
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), fromLayer:nil) - pausedTime;
        layer.beginTime = timeSincePause;
    }
    
    
    //MARK: Action
    
    func openDoor(){
        self.networkManager.sendAction()
        self.startAnimatingLoader()
    }
    
    @IBAction func showQRReader(sender: AnyObject) {
        self.presentViewController(reader, animated: true) { () -> Void in
            
            let arrow = UIButton()
            arrow.setImage(UIImage(named: "arrow"), forState: .Normal)
            arrow.sizeToFit()
            arrow.frame = CGRectMake(20, 20, arrow.frame.size.width, arrow.frame.size.height)
            arrow.addTarget(self, action: "hideQRReader:", forControlEvents: UIControlEvents.TouchUpInside)
            
            let filter = UIImageView(frame: self.reader.view.frame)
            filter.image = UIImage(named: "filter")
            filter.contentMode = UIViewContentMode.ScaleToFill
            
            self.reader.view.addSubview(filter)
            self.reader.view.addSubview(arrow)
        }

    }
    
    func hideQRReader(sender: AnyObject){
        self.reader.dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: MDNetworkManagerDelegate methods
    
    func didConnect(){
        self.updateLabelText()
    }
    
    func didFailConnected(error:String){
        print(error, appendNewline: false)
    }
    
    func didReceivedData(json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            let title = (isOpen ? kClose : kOpen)
            self.button.setTitle(title, forState: .Normal)
            self.updateLabelText()
        }
    }
    
    func didReceivedState(json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            let title = (isOpen ? kClose : kOpen)
            self.button.setTitle(title, forState: .Normal)
            self.updateLabelText()
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
}

