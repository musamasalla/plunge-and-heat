//
//  Plunge___Heat___Cold_Plunge_and_Sauna_Session_TrackerApp.swift
//  Plunge & Heat - Cold Plunge and Sauna Session Tracker
//
//  Created by Musa Masalla on 2025/12/17.
//

import SwiftUI

@main
struct Plunge___Heat___Cold_Plunge_and_Sauna_Session_TrackerApp: App {
    // Initialize WatchConnectivity for Apple Watch sync
    @StateObject private var watchConnectivity = WatchConnectivityManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivity)
        }
    }
}
