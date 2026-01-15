//
//  AccessibilityManager.swift
//  Clicky
//
//  Handles Accessibility (TCC) permission requests for global event taps
//

import Cocoa
import ApplicationServices

/// Manages Accessibility permissions required for global keyboard event monitoring
final class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    /// Whether accessibility permissions are currently granted
    @Published private(set) var isAccessibilityEnabled: Bool = false
    
    /// Timer for polling permission status
    private var permissionCheckTimer: Timer?
    
    private init() {
        checkAccessibility()
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Public Methods
    
    /// Checks if the app has accessibility permissions
    /// - Returns: true if permissions are granted
    @discardableResult
    func checkAccessibility() -> Bool {
        let trusted = AXIsProcessTrusted()
        
        DispatchQueue.main.async { [weak self] in
            self?.isAccessibilityEnabled = trusted
        }
        
        return trusted
    }
    
    /// Requests accessibility permissions by opening System Preferences
    /// This shows the system prompt if not already granted
    func requestAccessibility() {
        // This will prompt the user with a dialog to grant accessibility access
        // The kAXTrustedCheckOptionPrompt key triggers the system dialog
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        
        DispatchQueue.main.async { [weak self] in
            self?.isAccessibilityEnabled = trusted
        }
        
        // Start polling for changes if not yet trusted
        if !trusted {
            startPolling()
        }
    }
    
    /// Opens System Preferences to the Accessibility pane
    func openAccessibilityPreferences() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
        
        // Start polling since user might grant permission
        startPolling()
    }
    
    // MARK: - Private Methods
    
    /// Starts polling for permission changes
    private func startPolling() {
        stopPolling()
        
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let isEnabled = self.checkAccessibility()
            
            // Stop polling once permission is granted
            if isEnabled {
                self.stopPolling()
            }
        }
    }
    
    /// Stops polling for permission changes
    private func stopPolling() {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = nil
    }
}
