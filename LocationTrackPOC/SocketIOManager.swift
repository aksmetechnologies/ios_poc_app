//
//  SocketIOManager.swift
//  VBWorkorder
//
//  Created by Ravindra Kumar on 04/04/24.
//

import UIKit
import SocketIO

class SocketIOManager: NSObject {
    
    open class SocketConnection {
        
        public static let default_ = SocketConnection()
        let manager: SocketManager
        private init() {
            let token = UserDefaults.standard.string(forKey: "UserLocationTrackingSocket_Token")
            
            let params = ["Auth": "Bearer \(token!)"]
            let socketURL = URL.init(string: "https://socket.askmetechnologies.com")! as URL
//          let socketURL: URL = Utility.URLforRoute(route: route, params: params)! as URL
            
            self.manager = SocketManager(socketURL: socketURL, config: [.log(true),.version(.three),.extraHeaders(params)])
            manager.config = SocketIOClientConfiguration(arrayLiteral: .secure(true), .extraHeaders(params))
        }
    }
    
    private func connectSocket() {
        
        let socket = SocketConnection.default_.manager.defaultSocket
        if socket.status != .connected{
            socket.connect()
        }
        
        socket.on(clientEvent: .connect) {data, ack in
            print(data)
            print(ack)
            print("socket connected")
            self.getFinishAcknowledgement()
        }
        
        socket.on(clientEvent: .disconnect) {data, ack in
            
        }
        
        socket.on("unauthorized") { (data, ack) in
            print(data)
            print(ack)
            print("unauthorized user")
        }
    }
    
    private func disconnectSocket(){
        let socket = SocketConnection.default_.manager.defaultSocket
        socket.disconnect()
    }
    
    private func emitLatLng(){
        let socket = SocketConnection.default_.manager.defaultSocket
        if socket.status != .connected{return}
        let params:[String:Any] = ["lat":"lat","lng":"lng","rideId":"rideId"] as Dictionary
        print(params)
        socket.emitWithAck("Acknowledgement", params).timingOut(after: 5) {data in
            print(data)
        }
    }
    
    private func emitEndRide(){
        let socket = SocketConnection.default_.manager.defaultSocket
        let param:[String:Any] = ["rideId":"rideId"] as Dictionary
        socket.emitWithAck("Acknowledgement", param).timingOut(after: 5) {data in
            print(data)
        }
    }
    
    private func getFinishAcknowledgement(){
        let socket = SocketConnection.default_.manager.defaultSocket
        socket.on("Acknowledgement") {data, ack in
            print(data)
            socket.disconnect()
        }
    }
}

@objc class Utility: NSObject{
    static let main = Utility()
    fileprivate override init() {}
}

extension Utility{
    static func URLforRoute(route: String,params:[String: Any]) -> NSURL? {
        if let components: NSURLComponents  = NSURLComponents(string: route){
            var queryItems = [NSURLQueryItem]()
            for(key,value) in params {
                queryItems.append(NSURLQueryItem(name:key,value: "\(value)"))
            }
            components.queryItems = queryItems as [URLQueryItem]?
            return components.url as NSURL?
        }
        return nil
    }
}
