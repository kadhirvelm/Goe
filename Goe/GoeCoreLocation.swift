//
//  GoeCoreLocation.swift
//  Goe
//
//  Created by Kadhir M on 7/14/16.
//  Copyright © 2016 Expavar. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class GoeCoreLocationHelper: NSObject, CLLocationManagerDelegate{
    
    /** Geo coder. */
    let geoCoder = CLGeocoder()
    /** The location manager. */
    let locationManager = CLLocationManager()
    /** The user's current location. */
    private var currentLocation: CLLocationCoordinate2D?
    /** Current location object. */
    private var currentLocationObject: CLLocation?
    /** If false, the location manager is not enabled by user settings. */
    var enabled = true
    
    //MARK: Initialization
    
    override init() {
        super.init()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.startUpdatingLocation()
        } else {
            enabled = false
        }
    }
    
    deinit {
        locationManager.stopUpdatingLocation()
    }
    
    @objc func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.currentLocationObject = manager.location
        self.currentLocation = manager.location?.coordinate
    }
    
    //MARK: Methods Begin
    
    /** Given an address, returns the associated coordinates through the completion handler. */
    @nonobjc func returnLocation(address: String, completionHandler: (CLLocation?) -> Void) {
        returnCoordinates(address, completionHandler: completionHandler)
    }
    
    /** Fetches the actual coordinates and returns them through the completion handler. */
    @nonobjc private func returnCoordinates(address: String, completionHandler: (CLLocation?) -> Void) {
        let geocoder = CLGeocoder()
        var coordinate: CLLocationCoordinate2D?
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if error == nil {
                if let placemark = placemarks?.first {
                    coordinate = placemark.location!.coordinate
                    completionHandler(CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude))
                }
            }
        })
    }
    
    /** Given an address, returns the associated coordinates through the completion handler. */
    func returnLocation(address: String, completionHandler: (CLLocation?, UITextView?) -> Void, textView: UITextView?) {
        returnCoordinates(address, textView: textView, completionHandler: completionHandler)
    }
    
    /** Fetches the actual coordinates and returns them through the completion handler. */
    private func returnCoordinates(address: String, textView: UITextView?, completionHandler: (CLLocation?, UITextView?) -> Void) {
        let geocoder = CLGeocoder()
        var coordinate: CLLocationCoordinate2D?
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if error == nil {
                if let placemark = placemarks?.first {
                    coordinate = placemark.location!.coordinate
                    completionHandler(CLLocation(latitude: coordinate!.latitude, longitude: coordinate!.longitude), textView)
                }
            }
        })
    }
    
    /** Given a CLLocation, returns the closest proximal city through the completion handler. */
    func returnClosestCity(location: CLLocation, completionHandler: (String?, String?)->Void){
        geoCoder.reverseGeocodeLocation(location) { (placemarks, errors) in
            if errors == nil {
                let city = placemarks![0].addressDictionary!["City"] as? String
                let zipcode = placemarks![0].addressDictionary!["ZIP"] as? String
                completionHandler(city, zipcode)
            } else {
                print("Return closest city: \(errors)")
                completionHandler(nil, nil)
                //handle error case here
            }
        }
    }
    
    /** Returns the users location, waiting up to 5 seconds for it to register. */
    func returnUserLocation(completionHandler: (CLLocationCoordinate2D?) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            var totalWaitTime = 0
            while((self.currentLocation == nil)) {
                sleep(1)
                totalWaitTime += 1
                if totalWaitTime == 5 {
                    completionHandler(nil)
                }
            }
            completionHandler(self.currentLocation)
        }
    }
    
    /** Returns the users location, waiting up to 5 seconds for it to register. */
    @nonobjc func returnUserLocation(completionHandler: (CLLocation?) -> ()) {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)) {
            var totalWaitTime = 0
            while((self.currentLocationObject == nil)) {
                sleep(1)
                totalWaitTime += 1
                if totalWaitTime == 5 {
                    completionHandler(nil)
                    return
                }
            }
            completionHandler(self.currentLocationObject)
        }
    }
}
