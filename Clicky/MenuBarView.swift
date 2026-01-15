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
    @State private var showingAbout = false
    
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
                
                // About button
                Button(action: { showingAbout = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                
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
            
            // Sound Library Section
            VStack(alignment: .leading, spacing: 8) {
                Text("Sound Library")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                ForEach(HapticSoundPreset.allCases) { preset in
                    SoundPresetRow(
                        preset: preset,
                        isSelected: appState.soundPreset == preset,
                        onSelect: {
                            appState.soundPreset = preset
                        },
                        onTest: {
                            let original = appState.hapticManager.actuationType
                            appState.hapticManager.actuationType = preset.actuationType
                            appState.hapticManager.triggerHaptic()
                            appState.hapticManager.actuationType = original
                        }
                    )
                }
            }
            
            Divider()
            
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
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
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

// MARK: - Sound Preset Row

struct SoundPresetRow: View {
    let preset: HapticSoundPreset
    let isSelected: Bool
    let onSelect: () -> Void
    let onTest: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            // Selection indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? .accentColor : .secondary)
                .font(.system(size: 16))
            
            // Icon
            Image(systemName: preset.icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // Text
            VStack(alignment: .leading, spacing: 1) {
                Text(preset.displayName)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                Text(preset.subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Test button
            Button(action: onTest) {
                Image(systemName: "play.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Test this sound")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 64, height: 64)
            
            // App Name
            VStack(spacing: 4) {
                Text("Clicky")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text("Haptic feedback for your keyboard")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            // Creator
            VStack(spacing: 4) {
                Text("Created by Satwik")
                    .font(.subheadline)
                
                Button(action: {
                    if let url = URL(string: "https://github.com/mrsuperwealthy") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.caption)
                        Text("github.com/mrsuperwealthy")
                            .font(.caption)
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.blue)
            }
            
            Text("Open Source")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(24)
        .frame(width: 240)
    }
}

#Preview {
    MenuBarView()
}
