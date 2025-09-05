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
        MapView(mapManager: mapManager)
    }
}

#Preview {
    ContentView()
}
