//
//  HeadingService.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import Foundation
import CoreLocation

protocol HeadingServiceDelegate: AnyObject {
    func headingService(_ service: HeadingService, didUpdateHeading heading: Double, accuracy: Double, isUsingTrueNorth: Bool)
    func headingService(_ service: HeadingService, didFailWithError error: Error)
    func headingServiceDidBecomeUnavailable(_ service: HeadingService)
}

class HeadingService: NSObject, ObservableObject {
    weak var delegate: HeadingServiceDelegate?
    
    private let locationManager = CLLocationManager()
    private let maxAccuracy: Double = 25.0 // Maximum acceptable accuracy in degrees
    private var hasLocationFix: Bool = false
    private var locationUpdateTimer: Timer?
    
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
        
        // Start location updates briefly to get True North declination
        locationManager.startUpdatingLocation()
        
        // Stop location updates after 30 seconds to save battery
        locationUpdateTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: false) { [weak self] _ in
            self?.locationManager.stopUpdatingLocation()
        }
    }
    
    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
        locationUpdateTimer?.invalidate()
        locationUpdateTimer = nil
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
        let isUsingTrueNorth = newHeading.trueHeading >= 0 && hasLocationFix
        let heading = isUsingTrueNorth ? newHeading.trueHeading : newHeading.magneticHeading
        let accuracy = newHeading.headingAccuracy
        
        delegate?.headingService(self, didUpdateHeading: heading, accuracy: accuracy, isUsingTrueNorth: isUsingTrueNorth)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // We got a location fix, now we can use True North
        if !hasLocationFix {
            hasLocationFix = true
            print("Location fix acquired - True North now available")
        }
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
