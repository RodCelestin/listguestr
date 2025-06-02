//
//  ListGuestAPPApp.swift
//  ListGuestAPP
//
//  Created by Rodolphe Celestin on 2025-06-01.
//

import SwiftUI

@main
struct ListGuestAPPApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(EventService())
        }
    }
}
