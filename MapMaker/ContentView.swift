//
//  ContentView.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mapManager = MapManager()
    
    var body: some View {
        ZStack {
            // Compass view (contains map)
            CompassView(isCompassLocked: false, mapManager: mapManager)
            
            // Debug rotation values
            VStack {
                Spacer()
                HStack {
                    // Map rotation (blue) - bottom left
                    Text("Map: \(String(format: "%.1f", mapManager.mapRotationDisplay))°")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.leading, 20)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Device angle relative to compass arrow (green) - center bottom
                    Text("Device: \(String(format: "%.1f", mapManager.compassHeading))°")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.bottom, 20)
                    
                    Spacer()
                    
                    // Compass arrow rotation (red) - bottom right
                    Text("Arrow: \(String(format: "%.1f", mapManager.compassArrowRotation))°")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(12)
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(8)
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                }
            }
        }
        .onAppear {
            mapManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
