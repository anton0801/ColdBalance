import Foundation
import Combine

class BalanceViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var userId: String?
    
    private let firebaseService = FirebaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        authenticateAndLoad()
    }
    
    private func authenticateAndLoad() {
        isLoading = true
        
        // Check if already signed in
        if let userId = firebaseService.getCurrentUserId() {
            self.userId = userId
            loadData()
        } else {
            // Sign in anonymously
            firebaseService.signInAnonymously { [weak self] result in
                switch result {
                case .success(let userId):
                    self?.userId = userId
                    self?.loadData()
                case .failure(let error):
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }
    
    private func loadData() {
        guard let userId = userId else { return }
        
        // Load categories first
        firebaseService.fetchCategories(for: userId) { [weak self] result in
            switch result {
            case .success(let categories):
                self?.categories = categories
                // Initialize default categories if needed
                if categories.count == Category.defaultCategories.count {
                    self?.initializeDefaultCategories()
                }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
        
        // Observe transactions
        firebaseService.observeTransactions(for: userId) { [weak self] result in
            switch result {
            case .success(let transactions):
                self?.transactions = transactions
                self?.isLoading = false
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
                self?.isLoading = false
            }
        }
    }
    
    private func initializeDefaultCategories() {
        guard let userId = userId else { return }
        
        for var category in Category.defaultCategories {
            category.userId = userId
            firebaseService.saveCategory(category) { _ in }
        }
    }
    
    // MARK: - Computed Properties
    var totalIncome: Double {
        transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }
    }
    
    var totalExpense: Double {
        transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }
    }
    
    var balance: Double {
        totalIncome - totalExpense
    }
    
    var todayIncome: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return transactions
            .filter { $0.type == .income && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var todayExpense: Double {
        let today = Calendar.current.startOfDay(for: Date())
        return transactions
            .filter { $0.type == .expense && Calendar.current.isDate($0.date, inSameDayAs: today) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var todayBalance: Double {
        todayIncome - todayExpense
    }
    
    var monthIncome: Double {
        let now = Date()
        return transactions
            .filter { $0.type == .income && Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthExpense: Double {
        let now = Date()
        return transactions
            .filter { $0.type == .expense && Calendar.current.isDate($0.date, equalTo: now, toGranularity: .month) }
            .reduce(0) { $0 + $1.amount }
    }
    
    var monthBalance: Double {
        monthIncome - monthExpense
    }
    
    // MARK: - Actions
    func addTransaction(type: TransactionType, amount: Double, category: String, date: Date, note: String?) {
        guard let userId = userId else { return }
        
        let transaction = Transaction(
            type: type,
            amount: amount,
            category: category,
            date: date,
            note: note,
            userId: userId
        )
        
        firebaseService.saveTransaction(transaction) { [weak self] result in
            switch result {
            case .success:
                break // Real-time observer will update
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteTransaction(_ transaction: Transaction) {
        firebaseService.deleteTransaction(transaction) { [weak self] result in
            switch result {
            case .success:
                break // Real-time observer will update
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func addCategory(name: String, colorHex: String, icon: String) {
        guard let userId = userId else { return }
        
        let category = Category(name: name, colorHex: colorHex, icon: icon, userId: userId)
        
        firebaseService.saveCategory(category) { [weak self] result in
            switch result {
            case .success:
                self?.categories.append(category)
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    func deleteCategory(_ category: Category) {
        firebaseService.deleteCategory(category) { [weak self] result in
            switch result {
            case .success:
                self?.categories.removeAll { $0.id == category.id }
            case .failure(let error):
                self?.errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Insights
    func getBestSavingDay() -> (day: String, amount: Double)? {
        let calendar = Calendar.current
        var dailyBalances: [Date: Double] = [:]
        
        for transaction in transactions {
            let day = calendar.startOfDay(for: transaction.date)
            let amount = transaction.type == .income ? transaction.amount : -transaction.amount
            dailyBalances[day, default: 0] += amount
        }
        
        guard let best = dailyBalances.max(by: { $0.value < $1.value }) else {
            return nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return (formatter.string(from: best.key), best.value)
    }
    
    func getBiggestExpense() -> Transaction? {
        transactions
            .filter { $0.type == .expense }
            .max(by: { $0.amount < $1.amount })
    }
    
    func getAverageDailySpend() -> Double {
        let expenses = transactions.filter { $0.type == .expense }
        guard !expenses.isEmpty else { return 0 }
        
        let calendar = Calendar.current
        let uniqueDays = Set(expenses.map { calendar.startOfDay(for: $0.date) })
        let totalExpense = expenses.reduce(0) { $0 + $1.amount }
        
        return totalExpense / Double(uniqueDays.count)
    }
}
