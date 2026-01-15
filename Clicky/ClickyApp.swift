//
//  ClickyApp.swift
//  Clicky
//
//  Main application entry point - Menu Bar app with haptic feedback on spacebar
//

import SwiftUI
import AppKit

@main
struct ClickyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Empty scene - we're a menu bar only app
        Settings {
            EmptyView()
        }
    }
}

/// AppDelegate handles menu bar setup and lifecycle
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        
        // Check accessibility on launch
        if !AccessibilityManager.shared.isAccessibilityEnabled {
            // Give user a moment to see the UI before prompting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                AccessibilityManager.shared.requestAccessibility()
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Clean up
        InputManager.shared.stop()
    }
    
    private func setupMenuBar() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "hand.tap.fill", accessibilityDescription: "Clicky")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        // Create the popover
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 280, height: 380)
        popover?.behavior = .transient
        popover?.animates = true
        popover?.contentViewController = NSHostingController(rootView: MenuBarView())
    }
    
    @objc private func togglePopover() {
        guard let popover = popover, let button = statusItem?.button else { return }
        
        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            
            // Ensure popover window becomes key to receive keyboard events
            popover.contentViewController?.view.window?.makeKey()
        }
    }
}
