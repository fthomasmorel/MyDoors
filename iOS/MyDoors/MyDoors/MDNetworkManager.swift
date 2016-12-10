 //
//  MDNetworkManager.swift
//  MyDoors
//
//  Created by Florent TM on 09/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import Foundation
import SocketIO

//App Transport Security has blocked a cleartext HTTP (http://) resource load since it is insecure. Temporary exceptions can be configured via your app's Info.plist file.

//MARK: Protocol declaration

protocol MDNetworkManagerDelegate{
    func didConnect()
    func didFailConnected(_ error:String)
    func didReceivedData(_ json:Dictionary<String, AnyObject>)
    func didReceivedState(_ json:Dictionary<String, AnyObject>)
}

//MARK: Constants declaration

let kId = "id"
let kHost = "host"
let kAuthKey = "auth_key"

let kConnectAction = "connect"
let kAuthAction = "auth"
let kPortailAction = "portail-action"
let kPortailState = "portail-state"
let kAPNSTokenAction = "apns-token"

let kAPNSOldToken = "apns_oldToken"
let kAPNSNewToken = "apns_newToken"
let kError = "error"
let kToken = "token"
let kOpen = "Open"
let kClose = "Close"


class MDNetworkManager: NSObject{
    
    //MARK: Attributes
    var socket:SocketIOClient!
    
    init(withDelegate delegate:MDNetworkManagerDelegate){
        super.init()
        let url = URL(string: "https://mydoors.thomasmorel.io/")
        self.socket = SocketIOClient(socketURL: url!)
        self.delegate = delegate
        self.connect()
    }
    
    var delegate:MDNetworkManagerDelegate!
    var token = ""
    
    //MARK: Public functions
    
    func connect(){
        socket.on(kConnectAction) {data, ack in
            self.onConnect()
        }
        socket.connect()
    }
    
    func sendAction(){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token as AnyObject?
        socket.emitWithAck(kPortailAction, json).timingOut(after: 30000, callback: { (ack:Array<Any>?) -> Void in
            if let res = ack {
                self.onAckAction(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }
    
    func sendAPNSToken(_ apnsToken:String){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token as AnyObject?
        if let oldToken = UserDefaults.standard.object(forKey: kAPNSOldToken) as? String{
            json[kAPNSOldToken] = oldToken as AnyObject?
        }else{
            json[kAPNSOldToken] = apnsToken as AnyObject?
        }
        json[kAPNSNewToken] = apnsToken as AnyObject?
        
        socket.emitWithAck(kAPNSTokenAction, json).timingOut(after: 30000, callback: { (ack:Array<Any>?) -> Void in
            
            if let json = ack?[0] as? NSDictionary{
                switch(json[kError] as? String){
                case (.some(let error)):
                    print(error)
                    break
                case (.none):
                    UserDefaults.standard.set(apnsToken, forKey: kAPNSOldToken)
                    break
                }
            }

        })
    }

    //MARK: Private functions
    
    fileprivate func auth(){
        var json = Dictionary<String,AnyObject>()
        json[kAuthKey] = UserDefaults.standard.object(forKey: kAuthKey) as! String as AnyObject?
        
        socket.emitWithAck(kAuthAction, json).timingOut(after: 30000, callback: { (ack:Array<Any>?) -> Void in
            if let json = ack?[0] as? NSDictionary{
                switch(json[kError] as? String,json[kToken] as? String){
                case (.some(let error), .some):
                    self.onAckAuthWithError(error)
                case (.none, .some(let token)):
                    self.onAckAuthWithToken(token)
                default:
                    print("Unkown error")
                }
            }
        })
    }

    
    fileprivate func getState(){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token as AnyObject?
        socket.emitWithAck(kPortailState, json).timingOut(after: 30000, callback: { (ack:Array<Any>?) -> Void in
            if let res = ack {
                self.onAckState(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }
    
    fileprivate func onAckState(_ json:Dictionary<String, AnyObject>){
        delegate.didReceivedState(json)
    }
    
    fileprivate func onAckAction(_ json:Dictionary<String, AnyObject>){
        delegate.didReceivedData(json)
    }
    
    fileprivate func onAckAuthWithError(_ error:String){
        delegate.didFailConnected(error)
    }
    
    fileprivate func onAckAuthWithToken(_ token:String){
        self.token = token
        delegate.didConnect()
        self.getState()
    }
    
    fileprivate func onConnect(){
        self.auth()
    }
}
