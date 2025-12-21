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
    
    // Deep link state for widget quick actions
    @State private var deepLinkSessionType: SessionType?
    @State private var showLogSession = false
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchConnectivity)
                .sheet(isPresented: $showLogSession) {
                    if let sessionType = deepLinkSessionType {
                        LogSessionView(sessionType: sessionType)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // MARK: - Deep Link Handler
    
    private func handleDeepLink(_ url: URL) {
        // Handle widget deep links: plungeheat://log/cold or plungeheat://log/sauna
        guard url.scheme == "plungeheat",
              url.host == "log",
              let path = url.pathComponents.last else { return }
        
        switch path {
        case "cold":
            deepLinkSessionType = .coldPlunge
            showLogSession = true
        case "sauna":
            deepLinkSessionType = .sauna
            showLogSession = true
        default:
            break
        }
    }
}
