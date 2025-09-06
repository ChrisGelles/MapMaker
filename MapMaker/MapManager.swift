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
    @Published var rotation: Double = 110.0
    
    // Bounds checking
    private let minScale: CGFloat = 0.5
    private let maxScale: CGFloat = 3.0
    private let maxOffset: CGFloat = 500.0 // Maximum offset to prevent map from disappearing
    
    // Compass state
    @Published var isCompassActive: Bool = false
    @Published var compassHeading: Double = 0.0
    @Published var mapNorthOffset: Double = 0.0 // User-defined map north offset
    
    // Compass lock state
    @Published var isCompassLocked: Bool = false
    @Published var compassLockOffset: Double = 0.0 // Offset between map and compass when locked
    @Published var isLockPaused: Bool = false // Paused due to poor accuracy
    @Published var mapHeadingDelta: Double = 0.0 // Delta between heading and map rotation when locked
    
    // MARK: - Computed Properties
    var compassArrowRotation: Double {
        // The compass arrow uses .rotationEffect(.degrees(-heading))
        // So the actual rotation value is the negative of the compass heading
        return -compassHeading
    }
    
    var mapRotationDisplay: Double {
        // When locked, map rotation should equal heading minus delta
        // When unlocked, show actual map rotation
        return isCompassLocked ? (compassHeading - mapHeadingDelta) : rotation
    }
    
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
        
        // Load saved compass lock state
        loadCompassLockState()
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
        // Don't update compass display here - compass should be independent
    }
    
    private func updateCompassDisplay() {
        // Compass heading should only reflect actual device heading, not map rotation
        compassHeading = smoothedHeading
    }
    
    // MARK: - Compass Lock
    func toggleCompassLock() {
        if isCompassLocked {
            // Unlock: stop automatic adjustments
            isCompassLocked = false
            isLockPaused = false
            print("Compass lock disabled")
        } else {
            // Lock: capture current heading and map rotation values
            mapHeadingDelta = compassHeading - rotation
            isCompassLocked = true
            isLockPaused = false
            print("Compass lock enabled - Heading: \(compassHeading)°, Map: \(rotation)°, Delta: \(mapHeadingDelta)°")
        }
        saveCompassLockState()
    }
    
    func updateCompassLock() {
        guard isCompassLocked && !isLockPaused else { return }
        
        // Update map rotation to follow heading with captured delta
        // Map rotation = heading - delta
        let targetRotation = compassHeading - mapHeadingDelta
        rotation = targetRotation
        lastRotation = targetRotation
        print("Map following heading - Heading: \(compassHeading)°, Delta: \(mapHeadingDelta)°, Map: \(targetRotation)°")
    }
    
    func pauseCompassLock() {
        isLockPaused = true
        print("Compass lock paused due to poor accuracy")
    }
    
    func resumeCompassLock() {
        isLockPaused = false
        print("Compass lock resumed")
    }
    
    // MARK: - Pan Gesture
    func updatePan(translation: CGSize) {
        // Check for valid rotation before using it
        guard rotation.isFinite else {
            print("Invalid rotation in pan gesture: \(rotation), using 0 degrees")
            // Use simple pan without rotation transformation
            let newOffset = CGSize(
                width: lastPanOffset.width + translation.width,
                height: lastPanOffset.height + translation.height
            )
            offset = CGSize(
                width: max(-maxOffset, min(maxOffset, newOffset.width)),
                height: max(-maxOffset, min(maxOffset, newOffset.height))
            )
            return
        }
        
        // Transform translation to account for map rotation
        let rotationRadians = rotation * .pi / 180.0
        let cosRotation = cos(rotationRadians)
        let sinRotation = sin(rotationRadians)
        
        // Check for NaN in trig calculations
        guard cosRotation.isFinite && sinRotation.isFinite else {
            print("Invalid trig calculations in pan gesture, using simple pan")
            let newOffset = CGSize(
                width: lastPanOffset.width + translation.width,
                height: lastPanOffset.height + translation.height
            )
            offset = CGSize(
                width: max(-maxOffset, min(maxOffset, newOffset.width)),
                height: max(-maxOffset, min(maxOffset, newOffset.height))
            )
            return
        }
        
        // Apply inverse rotation to translation vector
        let transformedTranslation = CGSize(
            width: translation.width * cosRotation + translation.height * sinRotation,
            height: -translation.width * sinRotation + translation.height * cosRotation
        )
        
        // Check for NaN in transformed translation
        guard transformedTranslation.width.isFinite && transformedTranslation.height.isFinite else {
            print("Invalid transformed translation, using simple pan")
            let newOffset = CGSize(
                width: lastPanOffset.width + translation.width,
                height: lastPanOffset.height + translation.height
            )
            offset = CGSize(
                width: max(-maxOffset, min(maxOffset, newOffset.width)),
                height: max(-maxOffset, min(maxOffset, newOffset.height))
            )
            return
        }
        
        // Calculate new offset with bounds checking
        let newOffset = CGSize(
            width: lastPanOffset.width + transformedTranslation.width,
            height: lastPanOffset.height + transformedTranslation.height
        )
        
        // Apply bounds checking to prevent map from disappearing
        offset = CGSize(
            width: max(-maxOffset, min(maxOffset, newOffset.width)),
            height: max(-maxOffset, min(maxOffset, newOffset.height))
        )
    }
    
    func endPan() {
        lastPanOffset = offset
        validateMapState()
    }
    
    // MARK: - Zoom Gesture
    func updateZoom(magnification: CGFloat) {
        let newScale = lastScale * magnification
        // Apply bounds checking to prevent extreme zoom
        scale = max(minScale, min(maxScale, newScale))
    }
    
    func endZoom() {
        lastScale = scale
        validateMapState()
    }
    
    // MARK: - Rotation Gesture
    func updateRotation(rotation: Double) {
        // Don't allow manual rotation when compass is locked
        guard !isCompassLocked else {
            print("Manual rotation disabled - compass is locked")
            return
        }
        
        // Check for NaN or infinite values
        guard rotation.isFinite else {
            print("Invalid rotation value detected: \(rotation), ignoring")
            return
        }
        
        let newRotation = lastRotation + rotation
        
        // Check for NaN or infinite values in result
        guard newRotation.isFinite else {
            print("Invalid rotation calculation result: \(newRotation), resetting rotation")
            self.rotation = lastRotation
            return
        }
        
        self.rotation = newRotation
        // Update map north offset based on rotation (for map orientation only)
        setMapNorthOffset(newRotation)
        print("Map rotation updated: \(self.rotation) degrees, map north offset: \(mapNorthOffset) degrees")
    }
    
    func endRotation() {
        // Validate rotation before saving
        guard rotation.isFinite else {
            print("Invalid rotation at end: \(rotation), resetting to last valid rotation")
            rotation = lastRotation
            return
        }
        
        lastRotation = rotation
        print("Map rotation ended: \(rotation) degrees, final map north offset: \(mapNorthOffset) degrees")
    }
    
    // MARK: - Validation Functions
    private func validateMapState() {
        // Check and fix any NaN values
        if !scale.isFinite {
            print("Invalid scale detected: \(scale), resetting to 1.0")
            scale = 1.0
            lastScale = 1.0
        }
        
        if !offset.width.isFinite || !offset.height.isFinite {
            print("Invalid offset detected: \(offset), resetting to zero")
            offset = .zero
            lastPanOffset = .zero
        }
        
        if !rotation.isFinite {
            print("Invalid rotation detected: \(rotation), resetting to 0.0")
            rotation = 0.0
            lastRotation = 0.0
        }
        
        if !mapNorthOffset.isFinite {
            print("Invalid map north offset detected: \(mapNorthOffset), resetting to 0.0")
            mapNorthOffset = 0.0
        }
    }
    
    // MARK: - Persistence
    private func saveCompassLockState() {
        UserDefaults.standard.set(isCompassLocked, forKey: "isCompassLocked")
        UserDefaults.standard.set(compassLockOffset, forKey: "compassLockOffset")
        UserDefaults.standard.set(mapHeadingDelta, forKey: "mapHeadingDelta")
    }
    
    private func loadCompassLockState() {
        isCompassLocked = UserDefaults.standard.bool(forKey: "isCompassLocked")
        compassLockOffset = UserDefaults.standard.double(forKey: "compassLockOffset")
        mapHeadingDelta = UserDefaults.standard.double(forKey: "mapHeadingDelta")
        print("Loaded compass lock state: locked=\(isCompassLocked), offset=\(compassLockOffset)°, delta=\(mapHeadingDelta)°")
    }
    
    // MARK: - Reset Functions
    func resetMap() {
        scale = 1.0
        offset = .zero
        rotation = 110.0
        lastScale = 1.0
        lastPanOffset = .zero
        lastRotation = 110.0
        mapNorthOffset = 0.0
        isCompassLocked = false
        isLockPaused = false
        compassLockOffset = 0.0
        mapHeadingDelta = 0.0
        saveCompassLockState()
        print("Map reset to default state")
    }
}

// MARK: - CLLocationManagerDelegate
extension MapManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard isCompassActive else { return }
        
        // Check heading accuracy - discard poor readings
        guard newHeading.headingAccuracy >= 0 && newHeading.headingAccuracy <= maxAccuracy else {
            print("Discarding heading with poor accuracy: \(newHeading.headingAccuracy)°")
            if isCompassLocked {
                pauseCompassLock()
            }
            return
        }
        
        // Resume compass lock if it was paused
        if isCompassLocked && isLockPaused {
            resumeCompassLock()
        }
        
        // Prefer true north, fall back to magnetic
        let rawHeading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        // Apply smoothing
        smoothedHeading = smoothHeading(rawHeading)
        
        // Update compass display with map north offset
        updateCompassDisplay()
        
        // Update compass lock if active
        if isCompassLocked {
            updateCompassLock()
        }
        
        print("Raw heading: \(rawHeading)°, Smoothed: \(smoothedHeading)°, Accuracy: \(newHeading.headingAccuracy)°, Display: \(compassHeading)°")
        print("Compass Arrow Rotation: \(-compassHeading)°")
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
