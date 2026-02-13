import Foundation

struct User: Codable {
    var id: String
    var currency: String
    var startOfMonth: Int // 1-28
    var createdAt: Date
    
    init(id: String, currency: String = "$", startOfMonth: Int = 1) {
        self.id = id
        self.currency = currency
        self.startOfMonth = startOfMonth
        self.createdAt = Date()
    }
}
