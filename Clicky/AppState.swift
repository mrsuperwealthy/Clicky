//
//  AppState.swift
//  Clicky
//
//  Central app state management
//

import SwiftUI
import Combine

/// Central state management for the Clicky app
final class AppState: ObservableObject {
    static let shared = AppState()
    
    // MARK: - Published Properties
    
    /// Whether the space-click feature is enabled
    @Published var isEnabled: Bool = false {
        didSet {
            handleEnabledChange()
        }
    }
    
    /// Haptic intensity (0.0 - 1.0)
    @Published var intensity: Double = 0.5 {
        didSet {
            HapticManager.shared.intensity = intensity
            saveSettings()
        }
    }
    
    /// Selected haptic type
    @Published var hapticType: ActuationType = .weak {
        didSet {
            HapticManager.shared.actuationType = hapticType
            saveSettings()
        }
    }
    
    // MARK: - Managers
    
    let accessibilityManager = AccessibilityManager.shared
    let inputManager = InputManager.shared
    let hapticManager = HapticManager.shared
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults keys
    private let enabledKey = "clicky.isEnabled"
    private let intensityKey = "clicky.intensity"
    private let hapticTypeKey = "clicky.hapticType"
    
    private init() {
        loadSettings()
        setupBindings()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Wire up the key press callback to trigger haptic
        inputManager.onKeyPressed = { [weak self] in
            guard let self = self, self.isEnabled else { return }
            self.hapticManager.triggerHaptic()
        }
        
        // Listen for accessibility changes
        accessibilityManager.$isAccessibilityEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                if enabled && self.isEnabled && !self.inputManager.isRunning {
                    self.inputManager.start()
                }
            }
            .store(in: &cancellables)
    }
    
    private func handleEnabledChange() {
        if isEnabled {
            if accessibilityManager.isAccessibilityEnabled {
                inputManager.start()
            } else {
                // Request permissions if not granted
                accessibilityManager.requestAccessibility()
            }
        } else {
            inputManager.stop()
        }
        saveSettings()
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        // Only restore enabled state if we have permissions
        if defaults.object(forKey: enabledKey) != nil {
            // Don't auto-enable on launch, require user action
            isEnabled = false
        }
        
        if defaults.object(forKey: intensityKey) != nil {
            intensity = defaults.double(forKey: intensityKey)
        }
        
        if let typeValue = defaults.object(forKey: hapticTypeKey) as? Int32,
           let type = ActuationType(rawValue: typeValue) {
            hapticType = type
        }
        
        // Apply loaded settings to managers
        hapticManager.intensity = intensity
        hapticManager.actuationType = hapticType
    }
    
    private func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isEnabled, forKey: enabledKey)
        defaults.set(intensity, forKey: intensityKey)
        defaults.set(hapticType.rawValue, forKey: hapticTypeKey)
    }
    
    /// Test haptic feedback
    func testHaptic() {
        hapticManager.triggerHaptic()
    }
}
