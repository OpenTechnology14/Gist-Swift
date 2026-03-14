import Foundation
import Combine

class StorageService: ObservableObject {
    @Published var groceryItems: [GroceryItem] = []
    @Published var orderItems: [GroceryItem] = []
    @Published var groceryCategories: [GroceryCategory] = GroceryCategory.defaults
    @Published var orderCategories: [GroceryCategory] = GroceryCategory.defaults

    private let groceryItemsKey = "groceryItems"
    private let orderItemsKey = "orderItems"
    private let groceryCategoriesKey = "groceryCategories"
    private let orderCategoriesKey = "orderCategories"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadAll()
    }

    private func loadAll() {
        groceryItems = load(key: groceryItemsKey) ?? []
        orderItems = load(key: orderItemsKey) ?? []
        groceryCategories = load(key: groceryCategoriesKey) ?? GroceryCategory.defaults
        orderCategories = load(key: orderCategoriesKey) ?? GroceryCategory.defaults
    }

    private func load<T: Codable>(key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func save<T: Codable>(_ value: T, key: String) {
        if let data = try? encoder.encode(value) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    // MARK: - Grocery List

    func addToGrocery(_ item: GroceryItem) {
        groceryItems.append(item)
        save(groceryItems, key: groceryItemsKey)
    }

    func removeFromGrocery(at offsets: IndexSet, categoryId: UUID) {
        let inCategory = groceryItems.indices.filter { groceryItems[$0].categoryId == categoryId }
        let toRemove = offsets.map { inCategory[$0] }
        groceryItems.remove(atOffsets: IndexSet(toRemove))
        save(groceryItems, key: groceryItemsKey)
    }

    func updateGroceryItem(_ item: GroceryItem) {
        if let idx = groceryItems.firstIndex(where: { $0.id == item.id }) {
            groceryItems[idx] = item
            save(groceryItems, key: groceryItemsKey)
        }
    }

    func toggleGroceryItem(_ item: GroceryItem) {
        if let idx = groceryItems.firstIndex(where: { $0.id == item.id }) {
            groceryItems[idx].isChecked.toggle()
            save(groceryItems, key: groceryItemsKey)
        }
    }

    func removeGroceryItem(_ item: GroceryItem) {
        groceryItems.removeAll { $0.id == item.id }
        save(groceryItems, key: groceryItemsKey)
    }

    func addGroceryCategory(_ category: GroceryCategory) {
        groceryCategories.append(category)
        save(groceryCategories, key: groceryCategoriesKey)
    }

    // MARK: - Order List

    func addToOrder(_ item: GroceryItem) {
        orderItems.append(item)
        save(orderItems, key: orderItemsKey)
    }

    func removeFromOrder(at offsets: IndexSet, categoryId: UUID) {
        let inCategory = orderItems.indices.filter { orderItems[$0].categoryId == categoryId }
        let toRemove = offsets.map { inCategory[$0] }
        orderItems.remove(atOffsets: IndexSet(toRemove))
        save(orderItems, key: orderItemsKey)
    }

    func updateOrderItem(_ item: GroceryItem) {
        if let idx = orderItems.firstIndex(where: { $0.id == item.id }) {
            orderItems[idx] = item
            save(orderItems, key: orderItemsKey)
        }
    }

    func toggleOrderItem(_ item: GroceryItem) {
        if let idx = orderItems.firstIndex(where: { $0.id == item.id }) {
            orderItems[idx].isChecked.toggle()
            save(orderItems, key: orderItemsKey)
        }
    }

    func removeOrderItem(_ item: GroceryItem) {
        orderItems.removeAll { $0.id == item.id }
        save(orderItems, key: orderItemsKey)
    }

    func addOrderCategory(_ category: GroceryCategory) {
        orderCategories.append(category)
        save(orderCategories, key: orderCategoriesKey)
    }
}
