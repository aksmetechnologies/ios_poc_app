//
//  AppDelegate.swift
//  LocationTrackPOC
//
//  Created by Ravindra Kumar on 11/04/24.
//

import UIKit
import SocketIO
import CoreLocation

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    
    
    private var manager:SocketManager? = nil
    var socket:SocketIOClient?  = nil
    private var userLocationSoketToken:String? = nil
    private var locationManager:CoreLocationManager? = nil
    static var appDelegateInstance:AppDelegate? = UIApplication.shared.delegate as? AppDelegate
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        self.disconnectSocket(isTerminating:true)
    }
    
    // MARK: UISceneSession Lifecycle
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
    
    internal func disconnectSocket(isTerminating:Bool) {
        if (self.socket != nil) {
            self.socket?.disconnect()
            if (isTerminating) {
                self.socket = nil
            }
        }
    }
    
    internal func connectSocket() {
        if self.socket != nil {
            if (self.socket!.status != .connected) {
                if (self.userLocationSoketToken != nil) {
                    self.socket!.connect()
                }
            }
        }
    }
    
    fileprivate func convertDictionaryToJSON(_ dictionary: [String: Any]) -> String? {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted) else {
           print("Something is wrong while converting dictionary to JSON data.")
           return nil
        }

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
           print("Something is wrong while converting JSON data to JSON string.")
           return nil
        }

        return jsonString
     }
    
    
    
    internal func performSendLongitudeAndLatitudeThroghSocket(completion: @escaping(_ cordinateJSON:String) -> Void)  {
        if (self.socket != nil) {
            if (self.socket!.status == .connected) {
                if (self.userLocationSoketToken != nil) {
                    if ((self.locationManager != nil) && (self.locationManager?.currentLocation != nil)) {
                        let coordinatesJSON : [String:Any] = ["id":"2", "client": "iOS", "coords": ["accuracy":"7299.12765", "latitude":"\(self.locationManager!.currentLocation!.coordinate.latitude)", "longitude":"\(self.locationManager!.currentLocation!.coordinate.longitude)"]] as? [String:Any] ?? [:]
                        if let output = convertDictionaryToJSON(coordinatesJSON) {
                            debugPrint("Input dictionary: \(coordinatesJSON)")
                            self.socket!.emit("driver:move", coordinatesJSON)
                            completion(output)
                        }
                    } else {
                        self.initLocationManager { isLocationInitialized in}
                    }
                }
            }
        }
    }
    
    internal func initLocationManager(completion: @escaping(_ isLocationInitialized: Bool) -> Void) {
        self.locationManager = CoreLocationManager.init(delegate: self)
        completion(true)
    }
    
    internal func connectToUserTrackingSocket(completion: @escaping(_ isConnected: Bool, _ dataDescription:String, _ ackDescription:String) -> Void) {
        
        if (self.manager != nil) {
            self.manager = nil
        }
        
        if (self.socket != nil) {
            self.socket?.disconnect()
            self.socket = nil
        }
        
        
        self.manager = SocketIOManager.SocketConnection.default_.manager
        self.socket = self.manager?.defaultSocket
        
        
        
        self.socket?.on(clientEvent: .connect) {data, ack in
            debugPrint("*** Socket Connected ***")
            debugPrint("__clientEvent___connect___ Socket Id : \(data.debugDescription)")
            debugPrint("__clientEvent___connect___ Status  : \(ack.debugDescription)")
            completion(true, self.socket?.sid ?? "", "\(String(describing: self.socket!.status))")
        }
        
        self.socket?.on(clientEvent: .error) { data, ack in
            debugPrint("__clientEvent___Error__ Data : \(data.debugDescription)")
            debugPrint("__clientEvent___Error___Ack  : \(ack.debugDescription)")
            completion(false, self.socket?.sid ?? "", ack.debugDescription)
        }
        
        self.socket?.on(clientEvent: .disconnect) { data, ack in
            debugPrint("Socket Disconnected")
            debugPrint("__clientEvent___disconnect____ Data Is : \(data.debugDescription)")
            debugPrint("___clientEvent___disconnect___ AcK Is  : \(ack.debugDescription)")
            completion(false,self.socket?.sid ?? "",ack.debugDescription)
        }
        
        self.socket?.onAny({ event in
            debugPrint("*** On Any Event Verified : \(event.event) \(event.description)")
        })
        
        self.socket?.on("driver:move", callback: { datas, ack in
            debugPrint("driver:move : \(datas.debugDescription) AND ACK : \(ack.debugDescription)")
            NotificationCenter.default.post(name: Notification.Name(rawValue: "KT_DriverMoved"), object: nil, userInfo: ["driverMove":"driver:move : \(datas.debugDescription) AND ACK : \(ack.debugDescription)"])
        })
        
        if self.socket != nil {
            if (self.socket!.status != .connected) {
                if (self.userLocationSoketToken != nil) {
                    self.socket!.connect()
                }
            }
        }
    }
    
    internal func executeApiToGetSocketToken( completion: @escaping(_ isLoggedIn: Bool, _ loggedUser: String, _ token:String) -> Void) {
        let parameters = ["email": "driver@askme.com", "password": "12345678"]
        let url = URL(string: "https://socket.askmetechnologies.com/api/v1/user/login")!
        
        let session = URLSession.shared
        var request = URLRequest(url: url)
        request.httpMethod = "POST" //set http method as POST
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) // pass dictionary to data object and set it as request body
        } catch let error {
            print(error.localizedDescription)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                return
            }
            guard let data = data else {
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] else {
                    return
                }
                debugPrint("\(json) AND token = \(String(describing: json["token"]))")
                self.userLocationSoketToken = json["token"] as? String
                UserDefaults.standard.setValue(self.userLocationSoketToken ?? "", forKey: "UserLocationTrackingSocket_Token")
                UserDefaults.standard.synchronize()
                completion(true, "driver@askme.com", self.userLocationSoketToken ?? "")
            } catch let error {
                debugPrint(error.localizedDescription)
                completion(false,"","")
            }
        })
        task.resume()
    }
}


extension AppDelegate : CoreLocationManagerDelegate {
    func locationManagerDidUpdateAuthorisation(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.locationManager?.locationManager?.startUpdatingLocation()
        self.locationManager?.locationManager?.startUpdatingHeading()
    }
    
    func locationManagerDidUpdateLocation(_ locationManager: CoreLocationManager, location: CLLocation) {
        self.performSendLongitudeAndLatitudeThroghSocket { cordinateJSON in
            
        }
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: CoreLocationManager, heading: CLHeading, accuracy: CLLocationDirection) {
        
    }
    
    func locationManagerDidEnterRegion(_ locationManager: CoreLocationManager, didEnterRegion region: CLRegion) {
        
    }
    
    func locationManagerDidExitRegion(_ locationManager: CoreLocationManager, didExitRegion region: CLRegion) {
        
    }
    
    func locationManagerDidDetermineState(_ locationManager: CoreLocationManager, didDetermineState state: CLRegionState, region: CLRegion) {
        
    }
    
    func locationManagerDidRangeBeacons(_ locationManager: CoreLocationManager, beacons: [CLBeacon], region: CLBeaconRegion) {
        
    }
}
