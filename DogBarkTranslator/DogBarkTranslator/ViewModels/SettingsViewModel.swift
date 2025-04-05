import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "AppTheme")
            ThemeManager.shared.currentTheme = selectedTheme
        }
    }
    @Published var notificationsEnabled = true
    
    init() {
        let savedTheme = UserDefaults.standard.string(forKey: "AppTheme") ?? AppTheme.system.rawValue
        self.selectedTheme = AppTheme(rawValue: savedTheme) ?? .system
        ThemeManager.shared.currentTheme = self.selectedTheme
    }
    
    
    
    func saveSettings() {
        
        UserDefaults.standard.set(notificationsEnabled, forKey: "Notifications")
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "AppTheme")
        }
    }
    
    private init() {
        if let savedTheme = UserDefaults.standard.string(forKey: "AppTheme") {
            currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        }
    }
} 
