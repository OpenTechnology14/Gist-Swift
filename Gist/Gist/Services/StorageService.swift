import Foundation
import Combine

class StorageService: ObservableObject {
    // MARK: - Limit helpers

    var maxLists: Int { AuthService.shared.profile?.maxLists ?? 4 }
    var maxItems: Int { AuthService.shared.profile?.maxItems ?? 50 }

    var canAddList:  Bool { groceryLists.count < maxLists }
    var canAddItem:  Bool { recentlyViewed.count < maxItems }

    // MARK: - Cloud sync

    /// Pull cloud data on sign-in and replace local state.
    @MainActor
    func pullFromCloud() async {
        guard AuthService.shared.isSignedIn else { return }
        let (lists, recent) = await CloudStorageService.shared.pullAll()
        if !lists.isEmpty  { groceryLists    = lists;  save(groceryLists,    key: groceryListsKey) }
        if !recent.isEmpty { recentlyViewed  = recent; save(recentlyViewed,  key: recentlyViewedKey) }
    }

    private func cloudSync(_ block: @escaping () async -> Void) {
        guard AuthService.shared.isSignedIn else { return }
        Task { await block() }
    }
    @Published var groceryItems: [GroceryItem] = []
    @Published var orderItems: [GroceryItem] = []
    @Published var groceryCategories: [GroceryCategory] = GroceryCategory.defaults
    @Published var orderCategories: [GroceryCategory] = GroceryCategory.defaults
    @Published var groceryLists: [GroceryList] = []
    @Published var recentlyViewed: [GroceryItem] = []

    private let groceryItemsKey = "groceryItems"
    private let orderItemsKey = "orderItems"
    private let groceryCategoriesKey = "groceryCategories"
    private let orderCategoriesKey = "orderCategories"
    private let groceryListsKey = "groceryLists"
    private let recentlyViewedKey = "recentlyViewed"

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        loadAll()
        if recentlyViewed.isEmpty && !groceryItems.isEmpty {
            recentlyViewed = groceryItems
            save(recentlyViewed, key: recentlyViewedKey)
        }
    }

    private func loadAll() {
        groceryItems = load(key: groceryItemsKey) ?? []
        orderItems = load(key: orderItemsKey) ?? []
        groceryCategories = load(key: groceryCategoriesKey) ?? GroceryCategory.defaults
        orderCategories = load(key: orderCategoriesKey) ?? GroceryCategory.defaults
        groceryLists = load(key: groceryListsKey) ?? []
        recentlyViewed = load(key: recentlyViewedKey) ?? []
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

    // MARK: - Grocery Lists

    func addGroceryList(name: String, emoji: String) {
        guard canAddList else { return }
        let list = GroceryList(name: name, emoji: emoji, sortOrder: groceryLists.count)
        groceryLists.append(list)
        save(groceryLists, key: groceryListsKey)
        cloudSync { await CloudStorageService.shared.upsertList(id: list.id, name: name, emoji: emoji, sortOrder: list.sortOrder) }
    }

    func removeGroceryList(at offsets: IndexSet) {
        let removed = offsets.map { groceryLists[$0] }
        groceryLists.remove(atOffsets: offsets)
        for i in groceryLists.indices { groceryLists[i].sortOrder = i }
        save(groceryLists, key: groceryListsKey)
        cloudSync { for list in removed { await CloudStorageService.shared.deleteList(id: list.id) } }
    }

    func reorderGroceryLists(from source: IndexSet, to destination: Int) {
        groceryLists.move(fromOffsets: source, toOffset: destination)
        for i in groceryLists.indices { groceryLists[i].sortOrder = i }
        save(groceryLists, key: groceryListsKey)
    }

    func addItemToList(_ item: GroceryItem, listId: UUID) {
        guard let idx = groceryLists.firstIndex(where: { $0.id == listId }) else { return }
        guard groceryLists[idx].items.count < maxItems else { return }
        groceryLists[idx].items.append(item)
        save(groceryLists, key: groceryListsKey)
        cloudSync { await CloudStorageService.shared.upsertItem(item, listId: listId, itemType: "list_item") }
    }

    func removeItemFromList(item: GroceryItem, listId: UUID) {
        guard let idx = groceryLists.firstIndex(where: { $0.id == listId }) else { return }
        groceryLists[idx].items.removeAll { $0.id == item.id }
        save(groceryLists, key: groceryListsKey)
        cloudSync { await CloudStorageService.shared.deleteItem(id: item.id) }
    }

    func toggleItemInList(item: GroceryItem, listId: UUID) {
        guard let listIdx = groceryLists.firstIndex(where: { $0.id == listId }),
              let itemIdx = groceryLists[listIdx].items.firstIndex(where: { $0.id == item.id }) else { return }
        groceryLists[listIdx].items[itemIdx].isChecked.toggle()
        save(groceryLists, key: groceryListsKey)
    }

    func updateItemInList(item: GroceryItem, listId: UUID) {
        guard let listIdx = groceryLists.firstIndex(where: { $0.id == listId }),
              let itemIdx = groceryLists[listIdx].items.firstIndex(where: { $0.id == item.id }) else { return }
        groceryLists[listIdx].items[itemIdx] = item
        save(groceryLists, key: groceryListsKey)
    }

    // MARK: - Recently Viewed

    func addToRecentlyViewed(from product: Product) {
        let defaultCategoryId = groceryCategories.first?.id ?? UUID()
        let item = GroceryItem(from: product, categoryId: defaultCategoryId)
        recentlyViewed.removeAll { $0.name.lowercased() == item.name.lowercased() }
        recentlyViewed.insert(item, at: 0)
        let limit = min(maxItems, 30)
        if recentlyViewed.count > limit { recentlyViewed = Array(recentlyViewed.prefix(limit)) }
        save(recentlyViewed, key: recentlyViewedKey)
        cloudSync { await CloudStorageService.shared.upsertItem(item, listId: nil, itemType: "recently_viewed") }
    }

    func moveToList(item: GroceryItem, listId: UUID) {
        recentlyViewed.removeAll { $0.id == item.id }
        save(recentlyViewed, key: recentlyViewedKey)
        addItemToList(item, listId: listId)
    }

    func removeFromRecentlyViewed(_ item: GroceryItem) {
        recentlyViewed.removeAll { $0.id == item.id }
        save(recentlyViewed, key: recentlyViewedKey)
        cloudSync { await CloudStorageService.shared.deleteItem(id: item.id) }
    }

    // MARK: - Legacy Grocery List

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

    // MARK: - Legacy Order List

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
