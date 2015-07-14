//
//  MDNetworkManager.swift
//  MyDoors
//
//  Created by Florent TM on 09/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import Foundation
import Socket_IO_Client_Swift


protocol MDNetworkManagerDelegate{
    func didConnect()
    func didFailConnected(error:String)
    func didReceivedData(json:Dictionary<String, AnyObject>)
    func didReceivedState(json:Dictionary<String, AnyObject>)
}

let kAuthKey = "auth_key"
let kConnectAction = "connect"
let kAuthAction = "auth"
let kPortailAction = "portail-action"
let kPortailState = "portail-state"
let kError = "error"
let kToken = "token"

class MDNetworkManager: NSObject{

//    let socket = SocketIOClient(socketURL: "10.0.1.6:8080")
    
    
    let socket = SocketIOClient(socketURL: "192.168.1.24:8080")
    var delegate:MDNetworkManagerDelegate!
    var token = ""
    
    func connect(){
        socket.on(kConnectAction) {data, ack in
            self.onConnect()
        }
        socket.connect()
    }
    
    func sendAction(){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token
        socket.emitWithAck(kPortailAction, json).onAck(UInt64(30000), withCallback: { (ack:NSArray?) -> Void in
            if let res = ack {
                self.onAckAction(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }
    
    private func getState(){
        var json = Dictionary<String,AnyObject>()
        json[kToken] = self.token
        socket.emitWithAck(kPortailState, json).onAck(UInt64(30000), withCallback: { (ack:NSArray?) -> Void in
            if let res = ack {
                self.onAckState(res[0] as! Dictionary<String, AnyObject>)
            }
        })
    }
    
    private func auth(){
        var json = Dictionary<String,AnyObject>()
        json[kAuthKey] = NSUserDefaults.standardUserDefaults().objectForKey(kAuthKey) as! String
        socket.emitWithAck(kAuthAction, json).onAck(UInt64(30000), withCallback: { (ack:NSArray?) -> Void in
            if let res = ack {
                if let error = res[0][kError] as? String {
                    self.onAckAuthWithError(error)
                }else{
                    self.onAckAuthWithToken(res[0][kToken] as! String)
                }
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

}
