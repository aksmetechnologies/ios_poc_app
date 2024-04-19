//
//  CoreLocationManager.swift
//  VBWorkorder
//
//  Created by Ashok Kumar Ashok Kumar on 22/02/23.
//

import UIKit
import CoreLocation

protocol CoreLocationManagerDelegate: AnyObject {
    func locationManagerDidUpdateAuthorisation(_ manager: CLLocationManager,didChangeAuthorization status: CLAuthorizationStatus)
    func locationManagerDidUpdateLocation(_ locationManager: CoreLocationManager, location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: CoreLocationManager, heading: CLHeading, accuracy: CLLocationDirection)
    func locationManagerDidEnterRegion(_ locationManager: CoreLocationManager, didEnterRegion region: CLRegion)
    func locationManagerDidExitRegion(_ locationManager: CoreLocationManager, didExitRegion region: CLRegion)
    func locationManagerDidDetermineState(_ locationManager: CoreLocationManager, didDetermineState state: CLRegionState, region: CLRegion)
    func locationManagerDidRangeBeacons(_ locationManager: CoreLocationManager, beacons: [CLBeacon], region: CLBeaconRegion)
}

class CoreLocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    weak var delegate: CoreLocationManagerDelegate?
    var beaconsToRange: [CLBeaconRegion]?
    var currentLocation: CLLocation?
    
    init(delegate:CoreLocationManagerDelegate?) {
        super.init()
        self.initializeManager()
        self.delegate = delegate
    }
    
    func initializeManager() {
        self.beaconsToRange = []
        self.locationManager = CLLocationManager()
        self.locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager?.distanceFilter = kCLDistanceFilterNone
        self.locationManager?.activityType = .otherNavigation
        self.locationManager?.headingFilter = kCLHeadingFilterNone
        self.locationManager?.allowsBackgroundLocationUpdates = true
        self.locationManager?.pausesLocationUpdatesAutomatically = false
        self.locationManager?.delegate = self
        self.enableLocationServices()
    }
    
    func enableLocationServices() {
        self.checkStatus(status: CLLocationManager.authorizationStatus())
    }
    
    func stopLocationTrackingAndUpdation(completion: @escaping(_ success:Bool) -> Void) {
        self.locationManager?.stopUpdatingLocation()
        self.locationManager?.stopMonitoringVisits()
        self.locationManager?.stopUpdatingHeading()
        self.locationManager?.stopMonitoringSignificantLocationChanges()
        
        if #available(iOS 15.0, *) {
            self.locationManager?.stopMonitoringLocationPushes()
        }
        completion(true)
    }
    
    func checkStatus(status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager?.requestAlwaysAuthorization()
            break
            
        case .restricted, .denied:
            debugPrint("send an alert that the app will not function")
            break
            
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
            locationManager?.startUpdatingLocation()
            locationManager?.startUpdatingHeading()
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.startUpdatingHeading()
            break
        default:
            break
        }
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if manager.location != nil {
            self.currentLocation = manager.location
            self.delegate?.locationManagerDidUpdateLocation(self, location: manager.location!)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.delegate?.locationManagerDidUpdateHeading(self, heading: newHeading, accuracy: newHeading.headingAccuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {

    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        if region is CLBeaconRegion {
            if CLLocationManager.isRangingAvailable() {
                locationManager?.startRangingBeacons(in: region as! CLBeaconRegion)
                beaconsToRange?.append(region as! CLBeaconRegion)
            }
        } 
        self.delegate?.locationManagerDidEnterRegion(self, didEnterRegion: region)
    }
   
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        self.delegate?.locationManagerDidExitRegion(self, didExitRegion: region)
    }

    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if region is CLBeaconRegion {
            debugPrint("determined state of beacon")
            if CLLocationManager.isRangingAvailable() {
                debugPrint("determined state of beacon and started ranging")
                locationManager?.startRangingBeacons(in: region as! CLBeaconRegion)
                beaconsToRange?.append(region as! CLBeaconRegion)
            }
        }
        self.delegate?.locationManagerDidDetermineState(self, didDetermineState: state, region: region)
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                         didRangeBeacons beacons: [CLBeacon],
                         in region: CLBeaconRegion) {
        self.delegate?.locationManagerDidRangeBeacons(self, beacons: beacons, region: region)
    }
    
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
    
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        self.checkStatus(status: status)
        self.delegate?.locationManagerDidUpdateAuthorisation(manager, didChangeAuthorization: status)
    }
    
    
}

