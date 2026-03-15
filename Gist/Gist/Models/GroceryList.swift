import Foundation

struct GroceryList: Identifiable, Codable {
    var id = UUID()
    var name: String
    var emoji: String
    var sortOrder: Int
    var items: [GroceryItem] = []
}
