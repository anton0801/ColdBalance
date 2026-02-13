import Foundation
import FirebaseAuth
import FirebaseDatabase

class FirebaseService {
    static let shared = FirebaseService()
    private let database = Database.database().reference()
    private(set) var currentUserId: String?
    
    init() {}
    
    // MARK: - Authentication
    func signInAnonymously(completion: @escaping (Result<String, Error>) -> Void) {
        Auth.auth().signInAnonymously { authResult, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let userId = authResult?.user.uid {
                self.currentUserId = userId
                completion(.success(userId))
            }
        }
    }
    
    func getCurrentUserId() -> String? {
        if let userId = Auth.auth().currentUser?.uid {
            currentUserId = userId
            return userId
        }
        return nil
    }
    
    // MARK: - Transactions
    func saveTransaction(_ transaction: Transaction, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = database.child("transactions").child(transaction.userId).child(transaction.id)
        ref.setValue(transaction.toDictionary()) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchTransactions(for userId: String, completion: @escaping (Result<[Transaction], Error>) -> Void) {
        let ref = database.child("transactions").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            var transactions: [Transaction] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let transaction = Transaction.fromSnapshot(snapshot) {
                    transactions.append(transaction)
                }
            }
            
            completion(.success(transactions.sorted { $0.date > $1.date }))
        }
    }
    
    func observeTransactions(for userId: String, completion: @escaping (Result<[Transaction], Error>) -> Void) {
        let ref = database.child("transactions").child(userId)
        ref.observe(.value) { snapshot in
            var transactions: [Transaction] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let transaction = Transaction.fromSnapshot(snapshot) {
                    transactions.append(transaction)
                }
            }
            
            completion(.success(transactions.sorted { $0.date > $1.date }))
        }
    }
    
    func deleteTransaction(_ transaction: Transaction, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = database.child("transactions").child(transaction.userId).child(transaction.id)
        ref.removeValue { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    // MARK: - Categories
    func saveCategory(_ category: Category, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = database.child("categories").child(category.userId).child(category.id)
        ref.setValue(category.toDictionary()) { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func fetchCategories(for userId: String, completion: @escaping (Result<[Category], Error>) -> Void) {
        let ref = database.child("categories").child(userId)
        ref.observeSingleEvent(of: .value) { snapshot in
            var categories: [Category] = []
            
            for child in snapshot.children {
                if let snapshot = child as? DataSnapshot,
                   let category = Category.fromSnapshot(snapshot) {
                    categories.append(category)
                }
            }
            
            // If no categories, return defaults
            if categories.isEmpty {
                let defaults = Category.defaultCategories.map { cat in
                    Category(id: cat.id, name: cat.name, colorHex: cat.colorHex, icon: cat.icon, userId: userId)
                }
                completion(.success(defaults))
            } else {
                completion(.success(categories))
            }
        }
    }
    
    func deleteCategory(_ category: Category, completion: @escaping (Result<Void, Error>) -> Void) {
        let ref = database.child("categories").child(category.userId).child(category.id)
        ref.removeValue { error, _ in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
