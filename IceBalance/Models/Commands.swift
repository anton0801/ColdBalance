import Foundation

enum Command {
    // Lifecycle
    case initialize
    case shutdown
    
    // Data ingestion
    case ingestTracking([String: String])
    case ingestNavigation([String: String])
    
    // Operations
    case performValidation
    case fetchAttributionData
    case fetchDestination
    
    // Permissions
    case requestNotificationPermission
    case approveNotifications
    case declineNotifications
    case deferNotifications
    
    // Navigation
    case transitionToMain
    case transitionToWeb
    
    // Storage
    case persistTracking([String: String])
    case persistNavigation([String: String])
    case persistEndpoint(String)
    case persistMode(String)
    case persistPermissions(PermissionState)
    case markLaunched
}


enum Query {
    case getCurrentPhase
    case getEndpoint
    case getTracking
    case getNavigation
    case getPermissions
    case canRequestPermissions
    case shouldRunOrganicFlow
    case isLocked
}

enum DomainEvent {
    // Lifecycle
    case applicationStarted
    case applicationTimedOut
    case applicationLocked
    
    // Data
    case trackingIngested([String: String])
    case navigationIngested([String: String])
    case configurationRestored(RestoredConfig)
    
    // Validation
    case validationStarted
    case validationSucceeded
    case validationFailed
    
    // Attribution
    case attributionFetchStarted
    case attributionFetchSucceeded([String: String])
    case attributionFetchFailed
    
    // Destination
    case destinationFetchStarted
    case destinationFetchSucceeded(String)
    case destinationFetchFailed
    
    // Permissions
    case permissionRequested
    case permissionApproved
    case permissionDeclined
    case permissionDeferred
    
    // Navigation
    case navigatedToMain
    case navigatedToWeb
    case permissionSheetShown
    case offlineViewShown
    
    // Network
    case connectionEstablished
    case connectionLost
}

struct RestoredConfig {
    var tracking: [String: String]
    var navigation: [String: String]
    var mode: String?
    var firstLaunch: Bool
    var permissions: PermissionState
}

struct PermissionState: Equatable {
    var approved: Bool
    var declined: Bool
    var lastAsked: Date?
    
    var canAsk: Bool {
        guard !approved && !declined else { return false }
        if let date = lastAsked {
            return Date().timeIntervalSince(date) / 86400 >= 3
        }
        return true
    }
    
    static var initial: PermissionState {
        PermissionState(approved: false, declined: false, lastAsked: nil)
    }
}
