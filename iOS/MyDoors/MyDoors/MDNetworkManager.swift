//
//  MDNetworkManager.swift
//  MyDoors
//
//  Created by Florent TM on 09/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import Foundation
import Socket_IO_Client_Swift
import ReachabilitySwift

//App Transport Security has blocked a cleartext HTTP (http://) resource load since it is insecure. Temporary exceptions can be configured via your app's Info.plist file.

//MARK: Protocol declaration

protocol MDNetworkManagerDelegate{
    func didConnect()
    func didFailConnected(error:String)
    func didReceivedData(json:Dictionary<String, AnyObject>)
    func didReceivedState(json:Dictionary<String, AnyObject>)
}

//MARK: Constants declaration

let kId = "id"
let kLocalHost = "local_host"
let kRemoteHost = "remote_host"
let kAuthKey = "auth_key"
let kConnectAction = "connect"
let kAuthAction = "auth"
let kPortailAction = "portail-action"
let kPortailState = "portail-state"
let kError = "error"
let kToken = "token"
let kOpen = "Open"
let kClose = "Close"


class MDNetworkManager: NSObject{
    
    //MARK: Attributes
    var socket:SocketIOClient!
    
    init(withDelegate delegate:MDNetworkManagerDelegate){
        super.init()
        let reachability = Reachability.reachabilityForInternetConnection()!
        if reachability.isReachableViaWiFi(){
            self.socket = SocketIOClient(socketURL: NSUserDefaults.standardUserDefaults().objectForKey(kLocalHost) as! String)
        } else {
            self.socket = SocketIOClient(socketURL: NSUserDefaults.standardUserDefaults().objectForKey(kRemoteHost) as! String)
        }
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
        json[kToken] = self.token
        socket.emitWithAck(kPortailAction, json)(timeoutAfter:UInt64(30000), callback: { (ack:NSArray?) -> Void in
            if let res = ack {
                self.onAckAction(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }

    //MARK: Private functions
    
    private func auth(){
        var json = Dictionary<String,AnyObject>()
        json[kAuthKey] = NSUserDefaults.standardUserDefaults().objectForKey(kAuthKey) as! String
        
        socket.emitWithAck(kAuthAction, json)(timeoutAfter: UInt64(30000)) { (ack:NSArray?) -> Void in
            if let json = ack?.objectAtIndex(0) as? NSDictionary{
                switch(json[kError] as? String,json[kToken] as? String){
                case (.Some(let error), .Some):
                    self.onAckAuthWithError(error)
                case (.None, .Some(let token)):
                    self.onAckAuthWithToken(token)
                default:
                    print("Unkown error")
                }
            }
        }
        
    }

    
    private func getState(){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token
        socket.emitWithAck(kPortailState, json)(timeoutAfter:UInt64(30000), callback: { (ack:NSArray?) -> Void in
            if let res = ack {
                self.onAckState(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }
    
    private func onAckState(json:Dictionary<String, AnyObject>){
        delegate.didReceivedState(json)
    }
    
    private func onAckAction(json:Dictionary<String, AnyObject>){
        delegate.didReceivedData(json)
    }
    
    private func onAckAuthWithError(error:String){
        delegate.didFailConnected(error)
    }
    
    private func onAckAuthWithToken(token:String){
        self.token = token
        delegate.didConnect()
        self.getState()
    }
    
    private func onConnect(){
        self.auth()
    }
    
    func reachabilityChanged(note: NSNotification) {
        
        let reachability = note.object as! Reachability
        
        if reachability.isReachable() {
            if reachability.isReachableViaWiFi() {
                self.socket = SocketIOClient(socketURL: NSUserDefaults.standardUserDefaults().objectForKey(kLocalHost) as! String)
            } else {
                self.socket = SocketIOClient(socketURL: NSUserDefaults.standardUserDefaults().objectForKey(kRemoteHost) as! String)
            }
            self.connect()
        } else {
            print("Not reachable")
        }
    }
    

    
}
