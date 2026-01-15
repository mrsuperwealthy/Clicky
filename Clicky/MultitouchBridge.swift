//
//  MultitouchBridge.swift
//  Clicky
//
//  Bridge to Apple's private MultitouchSupport.framework for Force Touch haptic feedback
//

import Foundation
import IOKit
import SwiftUI

// MARK: - Private MultitouchSupport.framework API Declarations

/// Opaque type representing a Multitouch actuator (Taptic Engine)
typealias MTActuatorRef = CFTypeRef

/// Creates an actuator reference from a device ID
@_silgen_name("MTActuatorCreateFromDeviceID")
func MTActuatorCreateFromDeviceID(_ deviceID: UInt64) -> MTActuatorRef?

/// Opens the actuator for communication
@_silgen_name("MTActuatorOpen")
func MTActuatorOpen(_ actuator: MTActuatorRef) -> Int32

/// Closes the actuator
@_silgen_name("MTActuatorClose")
func MTActuatorClose(_ actuator: MTActuatorRef) -> Int32

/// Triggers haptic actuation (note: Float32 not Float64 based on HapticKey)
@_silgen_name("MTActuatorActuate")
func MTActuatorActuate(_ actuator: MTActuatorRef, _ actuationID: Int32, _ unknown1: UInt32, _ unknown2: Float32, _ unknown3: Float32) -> Int32

/// Checks if actuator is open
@_silgen_name("MTActuatorIsOpen")
func MTActuatorIsOpen(_ actuator: MTActuatorRef) -> Bool

// MARK: - IOKit Device Discovery

/// Discovers the Multitouch ID from IOKit registry
final class MultitouchDeviceDiscovery {
    
    /// Find the Multitouch ID for the built-in Force Touch trackpad
    static func findMultitouchID() -> UInt64? {
        var iterator: io_iterator_t = 0
        
        // Match AppleMultitouchDevice services
        guard let matching = IOServiceMatching("AppleMultitouchDevice") else {
            print("MultitouchDeviceDiscovery: Failed to create matching dictionary")
            return nil
        }
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator)
        guard result == KERN_SUCCESS else {
            print("MultitouchDeviceDiscovery: Failed to get matching services: \(result)")
            return nil
        }
        
        defer { IOObjectRelease(iterator) }
        
        var service: io_service_t = IOIteratorNext(iterator)
        while service != 0 {
            defer { 
                IOObjectRelease(service)
                service = IOIteratorNext(iterator)
            }
            
            // Get properties for this service
            var propertiesRef: Unmanaged<CFMutableDictionary>?
            let propResult = IORegistryEntryCreateCFProperties(service, &propertiesRef, kCFAllocatorDefault, 0)
            
            guard propResult == KERN_SUCCESS, let properties = propertiesRef?.takeRetainedValue() as? [String: Any] else {
                continue
            }
            
            let productName = properties["Product"] as? String ?? "Unknown"
            print("MultitouchDeviceDiscovery: Found device: \(productName)")
            
            // Check if this device supports actuation and is built-in
            let actuationSupported = (properties["ActuationSupported"] as? Bool) ?? false
            let mtBuiltIn = (properties["MT Built-In"] as? Bool) ?? false
            
            print("MultitouchDeviceDiscovery: ActuationSupported=\(actuationSupported), MT Built-In=\(mtBuiltIn)")
            
            guard actuationSupported && mtBuiltIn else {
                print("MultitouchDeviceDiscovery: Device not applicable, skipping")
                continue
            }
            
            // Get the Multitouch ID
            if let multitouchID = properties["Multitouch ID"] as? UInt64 {
                print("MultitouchDeviceDiscovery: Found Multitouch ID: \(String(format: "0x%llX", multitouchID)) for \(productName)")
                return multitouchID
            } else if let multitouchIDNumber = properties["Multitouch ID"] as? NSNumber {
                let multitouchID = multitouchIDNumber.uint64Value
                print("MultitouchDeviceDiscovery: Found Multitouch ID (NSNumber): \(String(format: "0x%llX", multitouchID)) for \(productName)")
                return multitouchID
            }
        }
        
        print("MultitouchDeviceDiscovery: No suitable device found")
        return nil
    }
}

// MARK: - Actuation Types (Raw IDs)
enum ActuationType: Int32 {
    case weak = 1        // Gentle click feedback
    case medium = 2      // Medium click / Double tap feel
    case strong = 3      // Strong click
    case buzz = 4        // Short buzz
    case doubleBuzz = 5  // Double buzz pattern
    case limit = 6       // Sharp "limit" click - metallic clack (Typewriter)
    case heavy = 15      // Heavy thunk (Force)
    case light = 16      // Light tap
    
    var description: String {
        switch self {
        case .weak: return "Weak Click"
        case .medium: return "Medium Click"
        case .strong: return "Strong Click"
        case .buzz: return "Buzz"
        case .doubleBuzz: return "Double Buzz"
        case .limit: return "Limit Click"
        case .heavy: return "Heavy"
        case .light: return "Light"
        }
    }
}

// MARK: - Haptic Sound Library Presets
enum HapticSoundPreset: String, CaseIterable, Identifiable {
    case mechanicalClick = "mechanical"   // Typewriter - actuationID: 6
    case heavyThud = "heavy"              // Force - actuationID: 15
    case doubleTap = "double"             // Double Tap - actuationID: 2
    case softClick = "soft"               // Soft - actuationID: 1
    case crispClick = "crisp"             // Crisp - actuationID: 3
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .mechanicalClick: return "Mechanical Click"
        case .heavyThud: return "Heavy Thud"
        case .doubleTap: return "Double Tap"
        case .softClick: return "Soft Click"
        case .crispClick: return "Crisp Click"
        }
    }
    
    var subtitle: String {
        switch self {
        case .mechanicalClick: return "Typewriter feel"
        case .heavyThud: return "Forceful thunk"
        case .doubleTap: return "Light double tap"
        case .softClick: return "Gentle feedback"
        case .crispClick: return "Sharp and clean"
        }
    }
    
    var icon: String {
        switch self {
        case .mechanicalClick: return "keyboard"
        case .heavyThud: return "hammer.fill"
        case .doubleTap: return "hand.tap"
        case .softClick: return "leaf.fill"
        case .crispClick: return "bolt.fill"
        }
    }
    
    var actuationType: ActuationType {
        switch self {
        case .mechanicalClick: return .limit    // ID: 6 - loudest metallic clack
        case .heavyThud: return .heavy          // ID: 15 - heavy thunk
        case .doubleTap: return .medium         // ID: 2 - double tap feel
        case .softClick: return .weak           // ID: 1 - gentle
        case .crispClick: return .strong        // ID: 3 - sharp
        }
    }
    
    var color: Color {
        switch self {
        case .mechanicalClick: return .purple
        case .heavyThud: return .red
        case .doubleTap: return .blue
        case .softClick: return .green
        case .crispClick: return .orange
        }
    }
}
