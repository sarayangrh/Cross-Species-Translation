//
//  DogBarkTranslatorApp.swift
//  DogBarkTranslator
//
//  Created by Yang on 2025-04-02.
//

import SwiftUI

@main
struct DogBarkTranslatorApp: App {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(themeManager.currentTheme.colorScheme)
                .environmentObject(themeManager)
        }
    }
}
