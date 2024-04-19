//
//  LocationSocket.swift
//  VBWorkorder
//
//  Created by Ravindra Kumar on 10/04/24.
//

import UIKit
import SocketIO

class LocationSocket: NSObject {
    
    static let shared = LocationSocket()

       var manager: SocketManager!
       var socket: SocketIOClient!
       var username: String!

       override init() {
           super.init()
           manager = SocketManager(socketURL: URL(string: "https://socket.askmetechnologies.com")!)
           socket = manager.socket(forNamespace: "/**********")
//         socket = manager.defaultSocket
       }

       func connect(auth: String) {
           socket.connect(withPayload: ["Auth": "Bearer \(auth)"])
           socket.on(clientEvent: .connect) { data, akt in
               debugPrint("**** Socket Connected")
           }
       }

       func disconnect() {
           socket.disconnect()
       }

       func sendMessage(_ message: String) {
           socket.emit("sendMessage", message)
       }

       func sendUsername(_ username: String) {
           socket.emit("sendUsername", username)
       }

       func receiveMessage(_ completion: @escaping (String, String, UUID) -> Void) {
           socket.on("receiveMessage") { data, _ in
               if let text = data[2] as? String,
                  let id = data[0] as? String,
                  let username = data[1] as? String {
                   completion(username, text, UUID.init(uuidString: id) ?? UUID())
               }
           }
       }

       func receiveNewUser(_ completion: @escaping (String, [String:String]) -> Void) {
           socket.on("receiveNewUser") { data, _ in
               if let username = data[0] as? String,
                  let users = data[1] as? [String:String] {
                   completion(username, users)
               }
           }
       }

}
