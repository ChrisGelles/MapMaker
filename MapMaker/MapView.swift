//
//  MapView.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import SwiftUI

struct MapView: View {
    @ObservedObject var mapManager: MapManager
    
    var body: some View {
        GeometryReader { geometry in
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
                
                // Compass line overlay
                if mapManager.isCompassActive {
                    CompassLineView()
                        .rotationEffect(.degrees(mapManager.compassHeading))
                }
                
                // Control buttons on the left side
                VStack {
                    Spacer()
                    
                    // Compass button
                    CompassButton(isActive: mapManager.isCompassActive) {
                        mapManager.toggleCompass()
                    }
                    
                    Spacer()
                }
                .padding(.leading, 20)
            }
        }
        .onAppear {
            mapManager.requestLocationPermission()
        }
    }
}

struct CompassButton: View {
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "location.north.fill")
                .font(.title2)
                .foregroundColor(isActive ? .white : .primary)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
                )
        }
    }
}

struct CompassLineView: View {
    var body: some View {
        VStack {
            // North-pointing arrow
            Triangle()
                .fill(Color.red)
                .frame(width: 20, height: 30)
                .offset(y: -150)
            
            // Line extending down from center
            Rectangle()
                .fill(Color.red)
                .frame(width: 2, height: 300)
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    MapView(mapManager: MapManager())
}
