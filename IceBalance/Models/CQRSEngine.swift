import Foundation
import Combine

@MainActor
final class CQRSEngine: ObservableObject {
    
    let readModel: ReadModel
    private let commandHandler: CommandHandler
    private let eventBus: EventBus
    
    @Published var showPermissionSheet: Bool = false
    @Published var showOfflineView: Bool = false
    @Published var navigateToMain: Bool = false
    @Published var navigateToWeb: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        let eventBus = EventBus()
        let readModel = ReadModel()
        let repository = DiskRepository()
        let commandHandler = CommandHandler(
            eventBus: eventBus,
            readModel: readModel,
            repository: repository
        )
        
        self.eventBus = eventBus
        self.readModel = readModel
        self.commandHandler = commandHandler
        
        // Wire EventBus → ReadModel
        wireEventBusToReadModel()
        
        wireReadModelToEngine()
    }
    
    // MARK: - Public API
    
    func execute(_ command: Command) {
        commandHandler.handle(command)
    }
    
    func query(_ query: Query) -> Any? {
        readModel.query(query)
    }
    
    private func wireEventBusToReadModel() {
        eventBus.events.sink { [weak readModel] event in
            readModel?.apply(event)
        }
        .store(in: &cancellables)
    }
    
    private func wireReadModelToEngine() {
        readModel.objectWillChange.sink { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.showPermissionSheet = self.readModel.showPermissionSheet
                self.showOfflineView = self.readModel.showOfflineView
                self.navigateToMain = self.readModel.navigateToMain
                self.navigateToWeb = self.readModel.navigateToWeb
            }
        }
        .store(in: &cancellables)
    }
}
