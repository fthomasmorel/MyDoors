//
//  InterfaceController.swift
//  MyDoorsWatch Extension
//
//  Created by Florent THOMAS-MOREL on 12/7/16.
//  Copyright © 2016 Florent THOMAS-MOREL. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire

enum DoorStatus {
    case loading
    case unkown
    case close
    case open
}

class InterfaceController: WKInterfaceController{
    
    @IBOutlet var imageView: WKInterfaceImage!
    @IBOutlet var actionLabel: WKInterfaceLabel!
    
    var status: DoorStatus = .loading
    var timer = Timer()
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        super.willActivate()
        self.updateUI()
        self.fetchDoorStatus()
        timer = Timer.scheduledTimer(timeInterval: 35.0, target: self, selector: #selector(InterfaceController.fetchDoorStatus), userInfo: nil, repeats: true)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func fetchDoorStatus(){
        let _ = Alamofire.request("https://mydoors.thomasmorel.io/tiny", method: .get, parameters: nil, encoding: JSONEncoding.default).responseString { response in
            if let result = String(data: response.data!, encoding: String.Encoding.utf8){
                self.updateStatus(status: result)
            }else{
                self.updateStatus(status: "unkown")
            }
            self.updateUI()
        }
    }
    
    func updateStatus(status: String){
        switch status {
        case "close":
            self.status = .close
        case "open":
            self.status = .open
        case "unkown":
            self.status = .unkown
        default:
            self.status = .loading
        }
    }
    
    func updateUI(){
        switch self.status {
        case .close:
            self.actionLabel.setText("Force Touch\nto Open")
            self.imageView.setImage(#imageLiteral(resourceName: "close"))
            self.imageView.setHidden(false)
        case .open:
            self.actionLabel.setText("Force Touch\nto Close")
            self.imageView.setImage(#imageLiteral(resourceName: "open"))
            self.imageView.setHidden(false)
        case .unkown:
            self.imageView.setHidden(true)
            self.actionLabel.setText("Cannot connect 😩")
        default:
            self.imageView.setHidden(true)
            self.actionLabel.setText("Loading...")
        }
    }
    
    @IBAction func sendCommandAction() {
        self.status = .loading
        self.updateUI()
        let _ = Alamofire.request("https://mydoors.thomasmorel.io/tiny", method: .post, parameters: nil, encoding: JSONEncoding.default).responseString { response in
            self.fetchDoorStatus()
        }
    }
    
}
