//
//  MapManager.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import SwiftUI
import CoreLocation

class MapManager: NSObject, ObservableObject {
    // Map state
    @Published var scale: CGFloat = 1.0
    @Published var offset: CGSize = .zero
    @Published var rotation: Double = 0.0
    
    // Compass state
    @Published var isCompassActive: Bool = false
    @Published var compassHeading: Double = 0.0
    
    // Gesture state
    private var lastPanOffset: CGSize = .zero
    private var lastScale: CGFloat = 1.0
    private var lastRotation: Double = 0.0
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func toggleCompass() {
        isCompassActive.toggle()
        
        if isCompassActive {
            locationManager.startUpdatingHeading()
        } else {
            locationManager.stopUpdatingHeading()
            // Lock the current orientation
            // The map will maintain its current rotation relative to north
        }
    }
    
    // MARK: - Pan Gesture
    func updatePan(translation: CGSize) {
        offset = CGSize(
            width: lastPanOffset.width + translation.width,
            height: lastPanOffset.height + translation.height
        )
    }
    
    func endPan() {
        lastPanOffset = offset
    }
    
    // MARK: - Zoom Gesture
    func updateZoom(magnification: CGFloat) {
        scale = lastScale * magnification
    }
    
    func endZoom() {
        lastScale = scale
    }
    
    // MARK: - Rotation Gesture
    func updateRotation(rotation: Double) {
        self.rotation = lastRotation + rotation
        print("Rotation updated: \(self.rotation) degrees")
    }
    
    func endRotation() {
        lastRotation = rotation
        print("Rotation ended: \(rotation) degrees")
    }
}

// MARK: - CLLocationManagerDelegate
extension MapManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isCompassActive else { return }
        
        // Update compass heading
        compassHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        print("Compass heading: \(compassHeading) degrees")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isCompassActive {
                locationManager.startUpdatingHeading()
            }
        case .denied, .restricted:
            print("Location access denied")
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            break
        }
    }
}
