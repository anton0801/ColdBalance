import Foundation
import FirebaseDatabase

enum TransactionType: String, Codable {
    case income = "income"
    case expense = "expense"
}

struct Transaction: Identifiable, Codable {
    var id: String = UUID().uuidString
    var type: TransactionType
    var amount: Double
    var category: String
    var date: Date
    var note: String?
    var userId: String
    
    enum CodingKeys: String, CodingKey {
        case id, type, amount, category, date, note, userId
    }
    
    init(id: String = UUID().uuidString, type: TransactionType, amount: Double, category: String, date: Date = Date(), note: String? = nil, userId: String) {
        self.id = id
        self.type = type
        self.amount = amount
        self.category = category
        self.date = date
        self.note = note
        self.userId = userId
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type.rawValue,
            "amount": amount,
            "category": category,
            "date": date.timeIntervalSince1970,
            "note": note ?? "",
            "userId": userId
        ]
    }
    
    static func fromSnapshot(_ snapshot: DataSnapshot) -> Transaction? {
        guard let dict = snapshot.value as? [String: Any],
              let id = dict["id"] as? String,
              let typeString = dict["type"] as? String,
              let type = TransactionType(rawValue: typeString),
              let amount = dict["amount"] as? Double,
              let category = dict["category"] as? String,
              let timestamp = dict["date"] as? TimeInterval,
              let userId = dict["userId"] as? String else {
            return nil
        }
        
        let date = Date(timeIntervalSince1970: timestamp)
        let note = dict["note"] as? String
        
        return Transaction(id: id, type: type, amount: amount, category: category, date: date, note: note, userId: userId)
    }
}
