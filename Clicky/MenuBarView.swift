//
//  MenuBarView.swift
//  Clicky
//
//  SwiftUI Menu Bar interface
//

import SwiftUI

/// Main menu bar popover view
struct MenuBarView: View {
    @ObservedObject var appState = AppState.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "hand.tap.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("Clicky")
                    .font(.headline)
                Spacer()
                statusIndicator
            }
            
            Divider()
            
            // Accessibility Warning (if needed)
            if !appState.accessibilityManager.isAccessibilityEnabled {
                accessibilityWarning
            }
            
            // Enable/Disable Toggle
            Toggle(isOn: $appState.isEnabled) {
                Label("Enable Haptic Keys", systemImage: appState.isEnabled ? "keyboard.fill" : "keyboard")
            }
            .toggleStyle(.switch)
            .disabled(!appState.accessibilityManager.isAccessibilityEnabled)
            
            Divider()
            
            // Haptic Type Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Haptic Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("Haptic Type", selection: $appState.hapticType) {
                    Text("Weak").tag(ActuationType.weak)
                    Text("Medium").tag(ActuationType.medium)
                    Text("Strong").tag(ActuationType.strong)
                    Text("Limit").tag(ActuationType.limit)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }
            
            // Intensity Slider
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Intensity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(appState.intensity * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
                
                Slider(value: $appState.intensity, in: 0.0...1.0, step: 0.05)
            }
            
            // Test Button
            Button(action: {
                appState.testHaptic()
            }) {
                Label("Test Haptic", systemImage: "waveform")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(!appState.hapticManager.isAvailable)
            
            Divider()
            
            // Status Info
            HStack {
                Circle()
                    .fill(appState.hapticManager.isAvailable ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(appState.hapticManager.isAvailable ? "Trackpad Ready" : "Trackpad Unavailable")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Quit Button
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit Clicky", systemImage: "power")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding()
        .frame(width: 280)
    }
    
    // MARK: - Subviews
    
    private var statusIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(appState.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(appState.isEnabled ? "On" : "Off")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var accessibilityWarning: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Accessibility Required")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Text("Clicky needs Accessibility permissions to detect keyboard events.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Grant Permission") {
                appState.accessibilityManager.requestAccessibility()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(10)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MenuBarView()
}
