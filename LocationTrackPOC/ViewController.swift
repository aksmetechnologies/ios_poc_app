//
//  ViewController.swift
//  LocationTrackPOC
//
//  Created by Ravindra Kumar on 11/04/24.
//

import UIKit
import SocketIO
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var btnLogin: UIButton!
    @IBOutlet weak var lblUser: UILabel!
    @IBOutlet weak var btnConnection: UIButton!
    @IBOutlet weak var lblConnection: UILabel!
    @IBOutlet weak var btnStartLocation: UIButton!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var btnSendLocation: UIButton!
    @IBOutlet weak var lblSentLoction: UILabel!
    
    
    private var manager:SocketManager? = nil
    var socket:SocketIOClient?  = nil
    private var userLocationSoketToken:String? = nil
    private var locationManager:CoreLocationManager? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(onDriverMove(notification:)), name: Notification.Name("KT_DriverMoved"), object: nil)
    }
    
    
    @objc func onDriverMove(notification:Notification) {
        if let userInfo = notification.userInfo as? [String:Any] {
            if (userInfo.keys.count > 0) {
                self.lblSentLoction.text = userInfo["driverMove"] as? String
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("KT_DriverMoved"), object: nil)
    }
    
    @IBAction func tappedUserSocketLogin(_ sender: UIButton) {
        self.btnLogin.setTitle("Login is in progress...", for: .normal)
        self.lblUser.text = ""
        AppDelegate.appDelegateInstance?.executeApiToGetSocketToken(completion: { isLoggedIn, loggedUser, token in
            if (isLoggedIn) {
                DispatchQueue.main.async {
                    self.btnLogin.setTitle("\(loggedUser)", for: .normal)
                    self.lblUser.text = "Logged User Token : \(token)"
                }
            }
        })
    }
    
    @IBAction func tappedConnectToSocket(_ sender: UIButton) {
        AppDelegate.appDelegateInstance?.connectToUserTrackingSocket(completion: { isConnected, dataDescription, ackDescription in
            if (isConnected){
                self.btnConnection.setTitle("Connected To : \(dataDescription)", for: .normal)
                self.lblConnection.text = "Connected socket ID : \(dataDescription) And Status : \(ackDescription)"
            } else {
                self.btnConnection.setTitle("Connect to Socket", for: .normal)
                self.lblConnection.text = "Socket not connected : \(dataDescription) And ACK : \(ackDescription)"
            }
        })
    }
    
    @IBAction func tappedStartLocation(_ sender: UIButton) {
//        AppDelegate.appDelegateInstance?.initLocationManager()
    }
    
    @IBAction func tappedSendLocation(_ sender: UIButton) {
        AppDelegate.appDelegateInstance?.performSendLongitudeAndLatitudeThroghSocket(completion: { cordinateJSON in
            self.btnSendLocation.setTitle("Sending Location Now", for: .normal)
            self.btnSendLocation.isEnabled = false
            self.lblSentLoction.text = cordinateJSON
        })
    }
    
}

