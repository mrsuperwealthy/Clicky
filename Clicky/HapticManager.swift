//
//  HapticManager.swift
//  Clicky
//
//  Manages Force Touch trackpad haptic feedback using private MultitouchSupport.framework
//

import Foundation

/// Manages haptic feedback via the Force Touch trackpad's Taptic Engine
final class HapticManager: ObservableObject {
    static let shared = HapticManager()
    
    /// Whether the haptic actuator is available and ready
    @Published private(set) var isAvailable: Bool = false
    
    /// Current haptic intensity (0.0 - 1.0)
    @Published var intensity: Double = 0.5
    
    /// Current actuation type
    @Published var actuationType: ActuationType = .weak
    
    // MARK: - Private Properties
    
    /// Reference to the Taptic Engine actuator
    private var actuator: MTActuatorRef?
    
    /// Cached multitouch device ID
    private var multitouchID: UInt64?
    
    /// Whether the actuator is currently open
    private var isOpen: Bool = false
    
    private init() {
        setupActuator()
    }
    
    deinit {
        closeActuator()
    }
    
    // MARK: - Public Methods
    
    /// Triggers a haptic click
    /// - Parameters:
    ///   - type: The type of haptic actuation (defaults to current setting)
    ///   - intensity: Intensity override (defaults to current setting)
    func triggerHaptic(type: ActuationType? = nil, intensity: Double? = nil) {
        // Try to reopen if needed
        if !isOpen || actuator == nil {
            openActuator()
        }
        
        guard isAvailable, isOpen, let actuator = actuator else {
            print("HapticManager: Actuator not available")
            return
        }
        
        let actuationType = type ?? self.actuationType
        let intensityValue = intensity ?? self.intensity
        
        // Clamp intensity to valid range
        let clampedIntensity = Float32(max(0.0, min(1.0, intensityValue)))
        
        // Trigger the haptic (using Float32 as per HapticKey implementation)
        let result = MTActuatorActuate(actuator, actuationType.rawValue, 0, clampedIntensity, 0.0)
        
        if result != 0 {
            print("HapticManager: Actuation failed with code \(result), retrying...")
            // Retry once by reopening
            closeActuator()
            openActuator()
            if let actuator = self.actuator {
                let retryResult = MTActuatorActuate(actuator, actuationType.rawValue, 0, clampedIntensity, 0.0)
                if retryResult != 0 {
                    print("HapticManager: Retry also failed with code \(retryResult)")
                }
            }
        }
    }
    
    /// Triggers a standard click haptic
    func click() {
        triggerHaptic(type: .weak)
    }
    
    /// Triggers a sharp limit click haptic
    func limitClick() {
        triggerHaptic(type: .limit)
    }
    
    /// Reinitializes the actuator (useful if device changes)
    func reinitialize() {
        closeActuator()
        multitouchID = nil
        setupActuator()
    }
    
    // MARK: - Private Methods
    
    /// Sets up the Taptic Engine actuator
    private func setupActuator() {
        // Use IOKit to discover the correct Multitouch ID
        print("HapticManager: Discovering multitouch device via IOKit...")
        
        if let discoveredID = MultitouchDeviceDiscovery.findMultitouchID() {
            multitouchID = discoveredID
            print("HapticManager: Using discovered Multitouch ID: \(String(format: "0x%llX", discoveredID))")
            openActuator()
        } else {
            print("HapticManager: IOKit discovery failed, trying fallback IDs...")
            tryFallbackDeviceIDs()
        }
    }
    
    /// Opens the actuator using the stored multitouch ID
    private func openActuator() {
        guard let deviceID = multitouchID else {
            print("HapticManager: No multitouch ID available")
            return
        }
        
        guard let act = MTActuatorCreateFromDeviceID(deviceID) else {
            print("HapticManager: Failed to create actuator for ID: \(String(format: "0x%llX", deviceID))")
            isAvailable = false
            return
        }
        
        let openResult = MTActuatorOpen(act)
        if openResult == 0 {
            actuator = act
            isOpen = true
            isAvailable = true
            print("HapticManager: Successfully opened actuator")
        } else {
            print("HapticManager: Failed to open actuator with code \(openResult)")
            isAvailable = false
        }
    }
    
    /// Try fallback device IDs if IOKit discovery fails
    private func tryFallbackDeviceIDs() {
        let knownDeviceIDs: [UInt64] = [
            0x200000001000000,
            0x100000001000000,
            0x2000000010000000,
            0x1000000010000000,
            0x300000001000000,
            0x1000000,
            1,
            0,
        ]
        
        for deviceID in knownDeviceIDs {
            print("HapticManager: Trying fallback device ID: \(String(format: "0x%llX", deviceID))")
            if let act = MTActuatorCreateFromDeviceID(deviceID) {
                print("HapticManager: Created actuator for device ID: \(String(format: "0x%llX", deviceID))")
                let openResult = MTActuatorOpen(act)
                if openResult == 0 {
                    actuator = act
                    multitouchID = deviceID
                    isOpen = true
                    isAvailable = true
                    print("HapticManager: Successfully opened actuator")
                    return
                } else {
                    print("HapticManager: Failed to open with code \(openResult)")
                }
            }
        }
        
        print("HapticManager: All fallback IDs failed")
        isAvailable = false
    }
    
    /// Closes the actuator connection
    private func closeActuator() {
        guard let actuator = actuator, isOpen else { return }
        
        let closeResult = MTActuatorClose(actuator)
        if closeResult == 0 {
            print("HapticManager: Actuator closed successfully")
        } else {
            print("HapticManager: Failed to close actuator with code \(closeResult)")
        }
        
        isOpen = false
        self.actuator = nil
    }
}
