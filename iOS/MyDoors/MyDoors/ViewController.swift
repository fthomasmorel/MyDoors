//
//  ViewController.swift
//  MyDoors
//
//  Created by Florent TM on 08/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import UIKit
import QRCodeReader

class ViewController: UIViewController, MDNetworkManagerDelegate, CAAnimationDelegate {

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
        self.button.addTarget(self, action: #selector(ViewController.startCircleAnimation), for: UIControlEvents.touchDown)
        self.button.addTarget(self, action: #selector(ViewController.endCircleAnimation), for: UIControlEvents.touchUpInside)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(ViewController.updateAPNSToken(_:)),
            name: NSNotification.Name(rawValue: "apnsTokenDidUpdate"),
            object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if !((UserDefaults.standard.object(forKey: kAuthKey)) != nil) {
            self.present(reader, animated: true) { () -> Void in
                
                let filter = UIImageView(frame: self.reader.view.frame)
                filter.image = UIImage(named: "filter")
                filter.contentMode = UIViewContentMode.scaleToFill
                
                self.reader.view.addSubview(filter)
            }
        }else{
            self.networkManager = MDNetworkManager(withDelegate: self)
            self.networkManager.connect()
        }
        
        self.initView()
        self.startAnimatingLoader()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if(flag){
            self.openDoor()
        }
    }
    
    //MARK : Private
    
    fileprivate func updateLabelText(){
        let today = Date()
        let calendar = Calendar.current
        let components = (calendar as NSCalendar).components([NSCalendar.Unit.hour, NSCalendar.Unit.minute], from: today)
        let hour = String(format: "%02d", components.hour!)
        let minutes = String(format: "%02d", components.minute!)
        updateLabel.text = "last update : \(hour):\(minutes)"
    }
    
    //MARK: QRReader
    
    func initQRReader(){
        reader.resultCallback = {
            print($1)
            do{
                let data = ($1).data(using: String.Encoding.utf8)!
                let res = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions())
                if let json = res as? NSDictionary, let id = json[kId] as? NSString{
                    if id == "com.thomasmorel.florent.MyDoors" {
                        UserDefaults.standard.set(json[kHost], forKey: kHost)
                        UserDefaults.standard.set(json[kAuthKey], forKey: kAuthKey)
                    }
                }
            }catch let error{
                print(error)
            }
            $0.dismiss(animated: true, completion: nil)
        }
    }
    
    
    //MARK: Animation
    
    func initView(){
        let radius = CGFloat(62)
        self.circle = CAShapeLayer()
        let bezier:UIBezierPath = (UIBezierPath(roundedRect: (rect: CGRect(x: 0, y: 0, width: 2*radius, height: 2*radius)), cornerRadius: radius))
        self.circle.path = bezier.cgPath
        let x = (self.button.frame.midX-radius)
        let y = (self.button.frame.midY-radius) + self.panel.frame.origin.y
        self.circle.position = CGPoint(x: x,y: y)
        self.circle.fillColor = UIColor.clear.cgColor;
        self.circle.strokeColor = self.button.titleLabel?.textColor.cgColor;
        self.circle.lineWidth = 5;
        self.circle.strokeEnd = 0.0;
        self.view.layer.addSublayer(self.circle);
        
    }

    func startAnimatingLoader(){
        border.isHidden = false
        let fullRotation = CGFloat(M_PI * 2)
        let animation = CAKeyframeAnimation()
        animation.keyPath = "transform.rotation.z"
        animation.duration = 1.2
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.repeatCount = Float.infinity
        animation.values = [0, fullRotation/4, fullRotation/2, fullRotation*3/4, fullRotation]
        border.layer.add(animation, forKey: "rotate")
    }
    
    func stopAnimatingLoader(){
        border.layer.removeAllAnimations()
        border.isHidden = true
    }
    
    func circleAnimation(){
        self.drawAnimation = CABasicAnimation(keyPath:"strokeEnd")
        self.drawAnimation.duration            = 1.0;
        self.drawAnimation.repeatCount         = 1.0;
        self.drawAnimation.fromValue = NSNumber(value: 0 as Float)
        self.drawAnimation.toValue   = NSNumber(value: 1 as Float)
        self.drawAnimation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        self.drawAnimation.delegate = self
        self.circle.add(self.drawAnimation, forKey:"draw")
    }
    
    func startCircleAnimation(){
        self.stopAnimatingLoader()
        self.circleAnimation()
    }
    
    func endCircleAnimation(){
        self.circle.removeAllAnimations()
        self.circle.removeFromSuperlayer()
        self.initView()
        
        if(self.border.isHidden){
            self.startAnimatingLoader()
        }
    }
    
    func pauseLayer(_ layer:CALayer){
        let pausedTime:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0;
        layer.timeOffset = pausedTime;
    }
    
    func resumeLayer(_ layer:CALayer){
        let pausedTime:CFTimeInterval = layer.timeOffset;
        layer.speed = 1.0;
        layer.timeOffset = 0.0;
        layer.beginTime = 0.0;
        let timeSincePause:CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from:nil) - pausedTime;
        layer.beginTime = timeSincePause;
    }
    
    
    //MARK: Action
    
    func openDoor(){
        self.networkManager.sendAction()
        self.startAnimatingLoader()
    }
    
    @IBAction func showQRReader(_ sender: AnyObject) {
        self.present(reader, animated: true) { () -> Void in
            
            let arrow = UIButton()
            arrow.setImage(UIImage(named: "arrow"), for: UIControlState())
            arrow.sizeToFit()
            arrow.frame = CGRect(x: 20, y: 20, width: arrow.frame.size.width, height: arrow.frame.size.height)
            arrow.addTarget(self, action: #selector(ViewController.hideQRReader(_:)), for: UIControlEvents.touchUpInside)
            
            let filter = UIImageView(frame: self.reader.view.frame)
            filter.image = UIImage(named: "filter")
            filter.contentMode = UIViewContentMode.scaleToFill
            
            self.reader.view.addSubview(filter)
            self.reader.view.addSubview(arrow)
        }

    }
    
    func hideQRReader(_ sender: AnyObject){
        self.reader.dismiss(animated: true, completion: nil)
    }
    
    //MARK: MDNetworkManagerDelegate methods
    
    func didConnect(){
        self.updateLabelText()
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func didFailConnected(_ error:String){
        //print(error, appendNewline: false)
    }
    
    func didReceivedData(_ json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            let title = (isOpen ? kClose : kOpen)
            self.button.setTitle(title, for: UIControlState())
            self.updateLabelText()
        }
    }
    
    func didReceivedState(_ json:Dictionary<String, AnyObject>){
        if let isOpen = json["isOpen"] as? Bool {
            let title = (isOpen ? kClose : kOpen)
            self.button.setTitle(title, for: UIControlState())
            self.updateLabelText()
        }
    }
    
    //MARK : Notification
    
    func updateAPNSToken(_ notification:Notification){
        if let token = (notification as NSNotification).userInfo![kAPNSNewToken] as? String {
            self.networkManager.sendAPNSToken(token)
        }
    }
    
    

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

