//
//  TodayViewController.swift
//  Extension
//
//  Created by Florent TM on 24/07/2015.
//  Copyright © 2015 Florent THOMAS-MOREL. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, MDNetworkManagerDelegate{
        
    @IBOutlet weak var doorLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var updateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if !((NSUserDefaults.standardUserDefaults().objectForKey(kAuthKey)) != nil) {
            self.doorLabel.text = "Can't connect to server"
        }else{
            self.doorLabel.text = "PORTAIL VERT"
            self.networkManager = MDNetworkManager()
            self.networkManager.delegate = self
            self.networkManager.connect()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.

        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData

        completionHandler(NCUpdateResult.NewData)
    }
    
    private func updateLabelText(){
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([NSCalendarUnit.Hour, NSCalendarUnit.Minute], fromDate: today)
        let hour = String(format: "%02d", components.hour)
        let minutes = String(format: "%02d", components.minute)
        updateLabel.text = "last update : \(hour):\(minutes)"
    }
    
    @IBAction func actionButton(sender: AnyObject) {
        self.networkManager.sendAction()
    }
    
    func didConnect(){
        self.updateLabelText()
    }
    
    func didFailConnected(error:String){
        self.doorLabel.text = error
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
    
}
