//
//  HeadingService.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import Foundation
import CoreLocation

protocol HeadingServiceDelegate: AnyObject {
    func headingService(_ service: HeadingService, didUpdateHeading heading: Double, accuracy: Double)
    func headingService(_ service: HeadingService, didFailWithError error: Error)
    func headingServiceDidBecomeUnavailable(_ service: HeadingService)
}

class HeadingService: NSObject, ObservableObject {
    weak var delegate: HeadingServiceDelegate?
    
    private let locationManager = CLLocationManager()
    private let maxAccuracy: Double = 25.0 // Maximum acceptable accuracy in degrees
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingOrientation = .portrait
        locationManager.headingFilter = 1.0 // 1 degree filter
    }
    
    var isHeadingAvailable: Bool {
        return CLLocationManager.headingAvailable()
    }
    
    func startUpdatingHeading() {
        guard isHeadingAvailable else {
            delegate?.headingServiceDidBecomeUnavailable(self)
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }
}

// MARK: - CLLocationManagerDelegate
extension HeadingService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Check heading accuracy - discard poor readings
        guard newHeading.headingAccuracy >= 0 && newHeading.headingAccuracy <= maxAccuracy else {
            return
        }
        
        // Prefer true north, fall back to magnetic
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        
        delegate?.headingService(self, didUpdateHeading: heading, accuracy: accuracy)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.headingService(self, didFailWithError: error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isHeadingAvailable {
                locationManager.startUpdatingHeading()
            } else {
                delegate?.headingServiceDidBecomeUnavailable(self)
            }
        case .denied, .restricted:
            delegate?.headingServiceDidBecomeUnavailable(self)
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
    
    // Allow iOS calibration prompt when needed
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
