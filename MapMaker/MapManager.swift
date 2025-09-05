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
    @Published var mapNorthOffset: Double = 0.0 // User-defined map north offset
    
    // Gesture state
    private var lastPanOffset: CGSize = .zero
    private var lastScale: CGFloat = 1.0
    private var lastRotation: Double = 0.0
    
    // Location manager
    private let locationManager = CLLocationManager()
    
    // Compass smoothing
    private var smoothedHeading: Double = 0.0
    private var lastValidHeading: Double = 0.0
    private let smoothingFactor: Double = 0.15 // Exponential smoothing factor (150-300ms feel)
    private let maxAccuracy: Double = 25.0 // Maximum acceptable accuracy in degrees
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Configure heading updates
        if CLLocationManager.headingAvailable() {
            locationManager.headingOrientation = .portrait
            locationManager.headingFilter = 2.0 // 2 degree filter to reduce spam
        }
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func toggleCompass() {
        isCompassActive.toggle()
        
        if isCompassActive {
            if CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            } else {
                print("Heading not available on this device")
                isCompassActive = false
            }
        } else {
            locationManager.stopUpdatingHeading()
        }
    }
    
    // MARK: - Compass Smoothing
    private func smoothHeading(_ newHeading: Double) -> Double {
        // Convert to unit vector for circular smoothing
        let currentRad = smoothedHeading * .pi / 180.0
        let newRad = newHeading * .pi / 180.0
        
        // Calculate circular difference
        let diff = newRad - currentRad
        let adjustedDiff = atan2(sin(diff), cos(diff))
        
        // Apply exponential smoothing
        let smoothedRad = currentRad + smoothingFactor * adjustedDiff
        let smoothedDegrees = smoothedRad * 180.0 / .pi
        
        // Normalize to 0-360
        return fmod(smoothedDegrees + 360.0, 360.0)
    }
    
    // MARK: - Map North Offset
    func setMapNorthOffset(_ offset: Double) {
        mapNorthOffset = offset
        updateCompassDisplay()
    }
    
    private func updateCompassDisplay() {
        // Apply map north offset to the smoothed heading
        compassHeading = fmod(smoothedHeading + mapNorthOffset + 360.0, 360.0)
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
        // Update map north offset based on rotation
        setMapNorthOffset(rotation)
        print("Rotation updated: \(self.rotation) degrees, map north offset: \(mapNorthOffset) degrees")
    }
    
    func endRotation() {
        lastRotation = rotation
        print("Rotation ended: \(rotation) degrees, final map north offset: \(mapNorthOffset) degrees")
    }
}

// MARK: - CLLocationManagerDelegate
extension MapManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isCompassActive else { return }
        
        // Check heading accuracy - discard poor readings
        guard newHeading.headingAccuracy >= 0 && newHeading.headingAccuracy <= maxAccuracy else {
            print("Discarding heading with poor accuracy: \(newHeading.headingAccuracy)°")
            return
        }
        
        // Prefer true north, fall back to magnetic
        let rawHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        // Apply smoothing
        smoothedHeading = smoothHeading(rawHeading)
        
        // Update compass display with map north offset
        updateCompassDisplay()
        
        print("Raw heading: \(rawHeading)°, Smoothed: \(smoothedHeading)°, Accuracy: \(newHeading.headingAccuracy)°, Display: \(compassHeading)°")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isCompassActive && CLLocationManager.headingAvailable() {
                locationManager.startUpdatingHeading()
            }
        case .denied, .restricted:
            print("Location access denied")
            isCompassActive = false
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
