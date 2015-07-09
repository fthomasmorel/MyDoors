//
//  MDNetworkManager.swift
//  MyDoors
//
//  Created by Florent TM on 09/07/2015.
//  Copyright (c) 2015 Florent THOMAS-MOREL. All rights reserved.
//

import Foundation
import Socket_IO_Client_Swift

class MDNetworkManager: NSObject{
    
    let socket = SocketIOClient(socketURL: "10.0.1.6:8080")
    
    func connect(){
        
        socket.on("connect") {data, ack in
            self.onConnect()
        }
        
        socket.on("portail-answer") {data, ack in
            self.onAnswer(data)
        }
        
        socket.connect()
    }
    
    func sendAction(json:Dictionary<String,AnyObject>){
        socket.emitWithAck("portail-action", json).onAck(UInt64(30000), withCallback: { (ack) -> Void in
            print("\(ack)")
        })
    }
    
    private func onAck(){
        
    }
    
    private func onConnect(){
        
    }
    
    private func onAnswer(data:NSArray?){
        
    }

}