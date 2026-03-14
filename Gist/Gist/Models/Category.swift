import Foundation

struct GroceryCategory: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var iconName: String
    var sortOrder: Int

    static let defaults: [GroceryCategory] = [
        GroceryCategory(name: "Produce", iconName: "leaf.fill", sortOrder: 0),
        GroceryCategory(name: "Dairy & Eggs", iconName: "drop.fill", sortOrder: 1),
        GroceryCategory(name: "Meat & Seafood", iconName: "fork.knife", sortOrder: 2),
        GroceryCategory(name: "Bakery", iconName: "birthday.cake.fill", sortOrder: 3),
        GroceryCategory(name: "Frozen", iconName: "snowflake", sortOrder: 4),
        GroceryCategory(name: "Beverages", iconName: "cup.and.saucer.fill", sortOrder: 5),
        GroceryCategory(name: "Snacks", iconName: "popcorn.fill", sortOrder: 6),
        GroceryCategory(name: "Pantry", iconName: "cabinet.fill", sortOrder: 7),
        GroceryCategory(name: "Household", iconName: "house.fill", sortOrder: 8),
        GroceryCategory(name: "Personal Care", iconName: "heart.fill", sortOrder: 9)
    ]
}
