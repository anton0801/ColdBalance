import Foundation
import Combine

// MARK: - ReadModel (CQRS - Query Side)

// UNIQUE: Optimized for reading, built from events
@MainActor
final class ReadModel: ObservableObject {
    
    // MARK: - Published State (for SwiftUI)
    @Published var showPermissionSheet: Bool = false
    @Published var showOfflineView: Bool = false
    @Published var navigateToMain: Bool = false
    @Published var navigateToWeb: Bool = false
    
    // MARK: - Internal State
    private(set) var phase: Phase = .idle
    private(set) var tracking: [String: String] = [:]
    private(set) var navigation: [String: String] = [:]
    private(set) var endpoint: String?
    private(set) var mode: String?
    private(set) var firstLaunch: Bool = true
    private(set) var permissions: PermissionState = .initial
    private(set) var isLocked: Bool = false
    
    enum Phase {
        case idle
        case initializing
        case validating
        case validated
        case fetching
        case ready(String)
        case failed
        case offline
    }
    
    func apply(_ event: DomainEvent) {
        switch event {
        case .applicationStarted:
            phase = .initializing
            
        case .applicationTimedOut:
            if !isLocked {
                phase = .failed
                navigateToMain = true
            }
            
        case .applicationLocked:
            isLocked = true
            
        case .trackingIngested(let data):
            tracking = data
            
        case .navigationIngested(let data):
            navigation = data
            
        case .configurationRestored(let config):
            tracking = config.tracking
            navigation = config.navigation
            mode = config.mode
            firstLaunch = config.firstLaunch
            permissions = config.permissions
            
        case .validationStarted:
            phase = .validating
            
        case .validationSucceeded:
            phase = .validated
            
        case .validationFailed:
            phase = .failed
            navigateToMain = true
            
        case .attributionFetchStarted:
            phase = .fetching
            
        case .attributionFetchSucceeded(let data):
            tracking = data
            
        case .attributionFetchFailed:
            phase = .failed
            navigateToMain = true
            
        case .destinationFetchStarted:
            phase = .fetching
            
        case .destinationFetchSucceeded(let url):
            endpoint = url
            mode = "Active"
            firstLaunch = false
            phase = .ready(url)
            isLocked = true
            
            if permissions.canAsk {
                showPermissionSheet = true
            } else {
                navigateToWeb = true
            }
            
        case .destinationFetchFailed:
            // No fallback - always fail without endpoint
            phase = .failed
            navigateToMain = true
            
        case .permissionApproved:
            permissions = PermissionState(approved: true, declined: false, lastAsked: Date())
            showPermissionSheet = false
            navigateToWeb = true
            
        case .permissionDeclined:
            permissions = PermissionState(approved: false, declined: true, lastAsked: Date())
            showPermissionSheet = false
            navigateToWeb = true
            
        case .permissionDeferred:
            permissions = PermissionState(approved: false, declined: false, lastAsked: Date())
            showPermissionSheet = false
            navigateToWeb = true 
            
        case .connectionLost:
            if !isLocked {
                showOfflineView = true
            }
            
        case .connectionEstablished:
            if !isLocked {
                showOfflineView = false
            }
            
        default:
            break
        }
    }
    
    // MARK: - Query Methods
    func query(_ query: Query) -> Any? {
        switch query {
        case .getCurrentPhase:
            return phase
            
        case .getEndpoint:
            return endpoint
            
        case .getTracking:
            return tracking
            
        case .getNavigation:
            return navigation
            
        case .getPermissions:
            return permissions
            
        case .canRequestPermissions:
            return permissions.canAsk
            
        case .shouldRunOrganicFlow:
            let isOrganic = tracking["af_status"] == "Organic"
            return isOrganic && firstLaunch
            
        case .isLocked:
            return isLocked
        }
    }
}
