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
            // Map Image
            Image("myFirstFloor")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .scaleEffect(mapManager.scale)
                .offset(mapManager.offset)
                .rotationEffect(.degrees(mapManager.rotation))
                .gesture(
                    SimultaneousGesture(
                        // Pan gesture
                        DragGesture()
                            .onChanged { value in
                                mapManager.updatePan(translation: value.translation)
                            }
                            .onEnded { _ in
                                mapManager.endPan()
                            },
                        
                        // Combined zoom and rotation gesture
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    mapManager.updateZoom(magnification: value)
                                }
                                .onEnded { _ in
                                    mapManager.endZoom()
                                },
                            
                            RotationGesture()
                                .onChanged { value in
                                    mapManager.updateRotation(rotation: value.degrees)
                                }
                                .onEnded { _ in
                                    mapManager.endRotation()
                                }
                        )
                    )
                )
            
            // Compass overlay
            CompassView()
        }
        .onAppear {
            mapManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
}
