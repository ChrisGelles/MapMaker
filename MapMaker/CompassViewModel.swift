//
//  CompassViewModel.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import Foundation
import SwiftUI

class CompassViewModel: NSObject, ObservableObject {
    // Published properties for UI
    @Published var smoothedHeading: Double = 0.0
    @Published var rawHeading: Double = 0.0
    @Published var accuracy: Double = 0.0
    @Published var isHeadingAvailable: Bool = true
    @Published var showAccuracyWarning: Bool = false
    
    // Smoothing parameters
    private let smoothingFactor: Double = 0.15 // Exponential smoothing factor (150-300ms feel)
    private var currentSmoothedHeading: Double = 0.0
    private var hasInitialHeading: Bool = false
    
    // Services
    private let headingService = HeadingService()
    
    override init() {
        super.init()
        headingService.delegate = self
        isHeadingAvailable = headingService.isHeadingAvailable
    }
    
    func startCompass() {
        headingService.startUpdatingHeading()
    }
    
    func stopCompass() {
        headingService.stopUpdatingHeading()
    }
    
    // MARK: - Circular Smoothing
    private func smoothHeading(_ newHeading: Double) -> Double {
        // Convert to unit vector for circular smoothing
        let currentRad = currentSmoothedHeading * .pi / 180.0
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
    
    // MARK: - Accuracy Assessment
    private func updateAccuracyStatus(_ accuracy: Double) {
        showAccuracyWarning = accuracy > 15.0
    }
    
    // MARK: - Debug Info
    var debugInfo: String {
        return String(format: "Raw: %.1f° | Smoothed: %.1f° | Accuracy: %.1f°", 
                     rawHeading, smoothedHeading, accuracy)
    }
}

// MARK: - HeadingServiceDelegate
extension CompassViewModel: HeadingServiceDelegate {
    func headingService(_ service: HeadingService, didUpdateHeading heading: Double, accuracy: Double) {
        DispatchQueue.main.async {
            self.rawHeading = heading
            self.accuracy = accuracy
            
            // Apply smoothing
            if !self.hasInitialHeading {
                self.currentSmoothedHeading = heading
                self.hasInitialHeading = true
            } else {
                self.currentSmoothedHeading = self.smoothHeading(heading)
            }
            
            self.smoothedHeading = self.currentSmoothedHeading
            self.updateAccuracyStatus(accuracy)
        }
    }
    
    func headingService(_ service: HeadingService, didFailWithError error: Error) {
        DispatchQueue.main.async {
            print("Heading service error: \(error.localizedDescription)")
        }
    }
    
    func headingServiceDidBecomeUnavailable(_ service: HeadingService) {
        DispatchQueue.main.async {
            self.isHeadingAvailable = false
        }
    }
}
