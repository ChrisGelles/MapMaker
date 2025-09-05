//
//  CompassView.swift
//  MapMaker
//
//  Created by Chris Gelles on 9/4/25.
//

import SwiftUI

struct CompassView: View {
    @StateObject private var viewModel = CompassViewModel()
    @State private var showDebugInfo = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if viewModel.isHeadingAvailable {
                    // Compass needle
                    CompassNeedleView(heading: viewModel.smoothedHeading, 
                                    accuracy: viewModel.accuracy,
                                    showWarning: viewModel.showAccuracyWarning)
                        .frame(width: min(geometry.size.width, geometry.size.height) * 0.8,
                               height: min(geometry.size.width, geometry.size.height) * 0.8)
                    
                    // Accuracy indicator
                    VStack {
                        Spacer()
                        AccuracyIndicator(accuracy: viewModel.accuracy)
                            .padding(.bottom, 50)
                    }
                    
                    // Debug info (tap to toggle)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showDebugInfo.toggle() }) {
                                Text("Debug")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(8)
                                    .background(Color.black.opacity(0.5))
                                    .cornerRadius(8)
                            }
                            .padding(.top, 20)
                            .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                    
                    // Debug panel
                    if showDebugInfo {
                        VStack {
                            Spacer()
                            DebugPanel(viewModel: viewModel)
                                .padding(.bottom, 100)
                        }
                    }
                } else {
                    // Unavailable state
                    VStack(spacing: 20) {
                        Image(systemName: "location.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                        
                        Text("Compass Unavailable")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            viewModel.startCompass()
        }
        .onDisappear {
            viewModel.stopCompass()
        }
    }
}

struct CompassNeedleView: View {
    let heading: Double
    let accuracy: Double
    let showWarning: Bool
    
    var body: some View {
        ZStack {
            // Compass needle
            CompassNeedle()
                .stroke(showWarning ? Color.orange : Color.red, lineWidth: 3)
                .rotationEffect(.degrees(-heading)) // Negative to point north when heading is 0
            
            // Center dot
            Circle()
                .fill(Color.white)
                .frame(width: 8, height: 8)
        }
    }
}

struct CompassNeedle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - 10
        
        // Main line from center to edge
        let endPoint = CGPoint(
            x: center.x + radius * cos(-90 * .pi / 180), // Point upward initially
            y: center.y + radius * sin(-90 * .pi / 180)
        )
        
        path.move(to: center)
        path.addLine(to: endPoint)
        
        // Arrowhead
        let arrowSize: CGFloat = 15
        let arrowAngle1: CGFloat = -270 + 30 // 30 degrees from main line
        let arrowAngle2: CGFloat = -270 - 30
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x + arrowSize * cos(arrowAngle1 * .pi / 180),
            y: endPoint.y + arrowSize * sin(arrowAngle1 * .pi / 180)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x + arrowSize * cos(arrowAngle2 * .pi / 180),
            y: endPoint.y + arrowSize * sin(arrowAngle2 * .pi / 180)
        )
        
        path.move(to: endPoint)
        path.addLine(to: arrowPoint1)
        path.move(to: endPoint)
        path.addLine(to: arrowPoint2)
        
        return path
    }
}

struct AccuracyIndicator: View {
    let accuracy: Double
    
    private var accuracyColor: Color {
        if accuracy < 10 {
            return .green
        } else if accuracy < 25 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var accuracyText: String {
        if accuracy < 10 {
            return "Excellent"
        } else if accuracy < 25 {
            return "Good"
        } else {
            return "Poor"
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(accuracyColor)
                .frame(width: 12, height: 12)
            
            Text(accuracyText)
                .font(.caption)
                .foregroundColor(.white)
            
            Text("(±\(String(format: "%.0f", accuracy))°)")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
    }
}

struct DebugPanel: View {
    @ObservedObject var viewModel: CompassViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Debug Info")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(viewModel.debugInfo)
                .font(.monospaced(.caption)())
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    CompassView()
}
