//
//  InputManager.swift
//  Clicky
//
//  Manages global keyboard event monitoring via CGEventTap
//

import Cocoa
import Carbon.HIToolbox

/// Manages global keyboard event listening using CGEventTap
final class InputManager: ObservableObject {
    static let shared = InputManager()
    
    /// Whether the event tap is currently running
    @Published private(set) var isRunning: Bool = false
    
    /// Callback triggered when any key is pressed
    var onKeyPressed: (() -> Void)?
    
    // MARK: - Private Properties
    
    /// The event tap reference
    private var eventTap: CFMachPort?
    
    /// Run loop source for the event tap
    private var runLoopSource: CFRunLoopSource?
    
    private init() {}
    
    deinit {
        stop()
    }
    
    // MARK: - Public Methods
    
    /// Starts listening for global keyboard events
    /// - Returns: true if started successfully
    @discardableResult
    func start() -> Bool {
        guard !isRunning else { return true }
        
        // Check accessibility permissions first
        guard AccessibilityManager.shared.isAccessibilityEnabled else {
            print("InputManager: Cannot start - Accessibility permissions not granted")
            return false
        }
        
        // Create event tap for key down events
        // We use CGEventTapLocation.cgSessionEventTap to capture events at the session level
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // Store self in a way that can be passed to C callback
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Handle tap disabled event (system may disable tap under certain conditions)
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    // Re-enable the tap
                    if let refcon = refcon {
                        let manager = Unmanaged<InputManager>.fromOpaque(refcon).takeUnretainedValue()
                        if let tap = manager.eventTap {
                            CGEvent.tapEnable(tap: tap, enable: true)
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }
                
                guard type == .keyDown else {
                    return Unmanaged.passUnretained(event)
                }
                
                // Trigger haptic for any key press
                if let refcon = refcon {
                    let manager = Unmanaged<InputManager>.fromOpaque(refcon).takeUnretainedValue()
                    
                    // Call the callback on main thread
                    DispatchQueue.main.async {
                        manager.onKeyPressed?()
                    }
                }
                
                // IMPORTANT: Pass the event through so keys still work in other apps
                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        )
        
        guard let eventTap = eventTap else {
            print("InputManager: Failed to create event tap. Check Accessibility permissions.")
            return false
        }
        
        // Create run loop source and add to current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        
        guard let runLoopSource = runLoopSource else {
            print("InputManager: Failed to create run loop source")
            self.eventTap = nil
            return false
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        isRunning = true
        print("InputManager: Started listening for all keyboard events")
        
        return true
    }
    
    /// Stops listening for keyboard events
    func stop() {
        guard isRunning else { return }
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
        
        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        }
        
        eventTap = nil
        runLoopSource = nil
        isRunning = false
        
        print("InputManager: Stopped listening for keyboard events")
    }
    
    /// Toggles the event tap on/off
    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }
}
