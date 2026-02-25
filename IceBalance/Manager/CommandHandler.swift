import Foundation
import UIKit
import UserNotifications
import Network
import Combine
import AppsFlyerLib

@MainActor
final class CommandHandler {
    
    private let eventBus: EventBus
    private let readModel: ReadModel
    private let repository: WriteRepository
    private var timeoutTask: Task<Void, Never>?
    private let networkMonitor = NWPathMonitor()
    
    init(eventBus: EventBus, readModel: ReadModel, repository: WriteRepository) {
        self.eventBus = eventBus
        self.readModel = readModel
        self.repository = repository
        
        setupNetworkMonitor()
    }
    
    // MARK: - Handle Command
    func handle(_ command: Command) {
        switch command {
        case .initialize:
            handleInitialize()
            
        case .shutdown:
            handleShutdown()
            
        case .ingestTracking(let data):
            handleIngestTracking(data)
            
        case .ingestNavigation(let data):
            handleIngestNavigation(data)
            
        case .performValidation:
            handlePerformValidation()
            
        case .fetchAttributionData:
            handleFetchAttributionData()
            
        case .fetchDestination:
            handleFetchDestination()
            
        case .requestNotificationPermission:
            handleRequestNotificationPermission()
            
        case .approveNotifications:
            handleApproveNotifications()
            
        case .declineNotifications:
            handleDeclineNotifications()
            
        case .deferNotifications:
            handleDeferNotifications()
            
        case .transitionToMain:
            eventBus.publish(.navigatedToMain)
            
        case .transitionToWeb:
            eventBus.publish(.navigatedToWeb)
            
        case .persistTracking(let data):
            repository.saveTracking(data)
            
        case .persistNavigation(let data):
            repository.saveNavigation(data)
            
        case .persistEndpoint(let url):
            repository.saveEndpoint(url)
            
        case .persistMode(let mode):
            repository.saveMode(mode)
            
        case .persistPermissions(let state):
            repository.savePermissions(state)
            
        case .markLaunched:
            repository.markLaunched()
        }
    }
    
    private func handleInitialize() {
        eventBus.publish(.applicationStarted)
        
        // Schedule timeout
        timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let locked = readModel.query(.isLocked) as? Bool, !locked else { return }
            eventBus.publish(.applicationTimedOut)
        }
        
        // Load config
        let config = repository.loadConfig()
        eventBus.publish(.configurationRestored(config))
    }
    
    private func handleShutdown() {
        timeoutTask?.cancel()
    }
    
    private func handleIngestTracking(_ data: [String: String]) {
        eventBus.publish(.trackingIngested(data))
        repository.saveTracking(data)
        
        // ✅ КРИТИЧНО: Firebase Validation СРАЗУ после tracking
        Task {
            await performValidation()
        }
    }
    
    private func handleIngestNavigation(_ data: [String: String]) {
        eventBus.publish(.navigationIngested(data))
        repository.saveNavigation(data)
    }
    
    private func handlePerformValidation() {
        Task { await performValidation() }
    }
    
    private func performValidation() async {
        // ✅ Проверяем locked перед валидацией
        guard let locked = readModel.query(.isLocked) as? Bool, !locked else {
            return
        }
        
        eventBus.publish(.validationStarted)
        
        do {
            let isValid = try await repository.validateFirebase()
            
            if isValid {
                eventBus.publish(.validationSucceeded)
                
                // ✅ После успешной валидации - бизнес-логика
                await executeBusinessLogic()
            } else {
                eventBus.publish(.validationFailed)
            }
        } catch {
            eventBus.publish(.validationFailed)
        }
    }
    
    private func handleFetchAttributionData() {
        Task { await fetchAttributionData() }
    }
    
    private func fetchAttributionData() async {
        guard let locked = readModel.query(.isLocked) as? Bool, !locked else { return }
        
        eventBus.publish(.attributionFetchStarted)
        
        // ✅ Задержка 5 секунд для органического
        try? await Task.sleep(nanoseconds: 5_000_000_000)
        
        do {
            let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
            var fetched = try await repository.fetchAttribution(deviceID: deviceID)
            
            // Merge с navigation
            if let navigation = readModel.query(.getNavigation) as? [String: String] {
                for (key, value) in navigation where fetched[key] == nil {
                    fetched[key] = value
                }
            }
            
            eventBus.publish(.attributionFetchSucceeded(fetched))
            repository.saveTracking(fetched)
            
            // ✅ После GCD fetch - запрос endpoint
            await fetchDestination()
            
        } catch {
            eventBus.publish(.attributionFetchFailed)
        }
    }
    
    private func handleFetchDestination() {
        Task { await fetchDestination() }
    }
    
    private func fetchDestination() async {
        guard let locked = readModel.query(.isLocked) as? Bool, !locked else { return }
        
        guard let tracking = readModel.query(.getTracking) as? [String: String],
              !tracking.isEmpty else {
            eventBus.publish(.destinationFetchFailed)
            return
        }
        
        eventBus.publish(.destinationFetchStarted)
        
        do {
            let endpoint = try await repository.fetchDestination(tracking: tracking)
            
            // ✅ Отменяем timeout
            timeoutTask?.cancel()
            
            eventBus.publish(.destinationFetchSucceeded(endpoint))
            eventBus.publish(.applicationLocked)
            
            repository.saveEndpoint(endpoint)
            repository.saveMode("Active")
            repository.markLaunched()
            
        } catch {
            eventBus.publish(.destinationFetchFailed)
        }
    }
    
    // ✅ БИЗНЕС-ЛОГИКА после Firebase Validation
    private func executeBusinessLogic() async {
        guard let shouldRunOrganic = readModel.query(.shouldRunOrganicFlow) as? Bool else {
            await fetchDestination()
            return
        }
        
        if shouldRunOrganic {
            // Органический первый запуск → GCD → backend
            await fetchAttributionData()
        } else {
            // Все остальные → backend сразу
            await fetchDestination()
        }
    }
    
    private func handleRequestNotificationPermission() {
        requestPermission()
    }
    
    private func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, _ in
            Task { @MainActor [weak self] in
                if granted {
                    self?.handle(.approveNotifications)
                } else {
                    self?.handle(.declineNotifications)
                }
            }
        }
    }
    
    private func handleApproveNotifications() {
        let state = PermissionState(approved: true, declined: false, lastAsked: Date())
        eventBus.publish(.permissionApproved)
        repository.savePermissions(state)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    private func handleDeclineNotifications() {
        let state = PermissionState(approved: false, declined: true, lastAsked: Date())
        eventBus.publish(.permissionDeclined)
        repository.savePermissions(state)
    }
    
    private func handleDeferNotifications() {
        let state = PermissionState(approved: false, declined: false, lastAsked: Date())
        eventBus.publish(.permissionDeferred)
        repository.savePermissions(state)
    }
    
    // MARK: - Network Monitor
    
    private func setupNetworkMonitor() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                if path.status == .satisfied {
                    self?.eventBus.publish(.connectionEstablished)
                } else {
                    self?.eventBus.publish(.connectionLost)
                }
            }
        }
        networkMonitor.start(queue: .global(qos: .background))
    }
}

final class EventBus {
    private let subject = PassthroughSubject<DomainEvent, Never>()
    
    var events: AnyPublisher<DomainEvent, Never> {
        subject.eraseToAnyPublisher()
    }
    
    func publish(_ event: DomainEvent) {
        subject.send(event)
    }
}
