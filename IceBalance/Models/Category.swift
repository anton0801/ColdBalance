import SwiftUI
import FirebaseDatabase

struct Category: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var colorHex: String
    var icon: String
    var userId: String
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "name": name,
            "colorHex": colorHex,
            "icon": icon,
            "userId": userId
        ]
    }
    
    static func fromSnapshot(_ snapshot: DataSnapshot) -> Category? {
        guard let dict = snapshot.value as? [String: Any],
              let id = dict["id"] as? String,
              let name = dict["name"] as? String,
              let colorHex = dict["colorHex"] as? String,
              let icon = dict["icon"] as? String,
              let userId = dict["userId"] as? String else {
            return nil
        }
        
        return Category(id: id, name: name, colorHex: colorHex, icon: icon, userId: userId)
    }
    
    static let defaultCategories = [
        Category(id: UUID().uuidString, name: "Salary", colorHex: "6FE3C1", icon: "dollarsign.circle.fill", userId: ""),
        Category(id: UUID().uuidString, name: "Food", colorHex: "FF8A8A", icon: "cart.fill", userId: ""),
        Category(id: UUID().uuidString, name: "Transport", colorHex: "4FC3F7", icon: "car.fill", userId: ""),
        Category(id: UUID().uuidString, name: "Entertainment", colorHex: "9FE6FF", icon: "tv.fill", userId: ""),
        Category(id: UUID().uuidString, name: "Shopping", colorHex: "FFB84D", icon: "bag.fill", userId: ""),
        Category(id: UUID().uuidString, name: "Health", colorHex: "FF6B9D", icon: "heart.fill", userId: "")
    ]
}
