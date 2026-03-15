import Foundation

/// Syncs lists and recently-viewed items to/from Supabase.
/// All methods are fire-and-forget (called in background Tasks from StorageService).
actor CloudStorageService {
    static let shared = CloudStorageService()

    private let session = URLSession.shared
    private let decoder = JSONDecoder()

    private var token:  String? { AuthService.shared.token }
    private var userId: String? { AuthService.shared.profile?.id }

    // MARK: - Lists

    func fetchLists() async -> [CloudList] {
        guard let token, let userId,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/lists?user_id=eq.\(userId)&order=sort_order") else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([CloudList].self, from: data)) ?? []
        } catch { return [] }
    }

    func upsertList(id: UUID, name: String, emoji: String, sortOrder: Int) async {
        guard let token, let userId,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/lists") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "id": id.uuidString.lowercased(), "user_id": userId,
            "name": name, "emoji": emoji, "sort_order": sortOrder,
        ])
        _ = try? await session.data(for: req)
    }

    func deleteList(id: UUID) async {
        guard let token,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/lists?id=eq.\(id.uuidString.lowercased())") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        _ = try? await session.data(for: req)
    }

    // MARK: - Items

    func fetchItems(listId: UUID? = nil, itemType: String? = nil) async -> [CloudItem] {
        guard let token, let userId else { return [] }
        var urlStr = "\(SupabaseConfig.url)/rest/v1/items?user_id=eq.\(userId)"
        if let listId  { urlStr += "&list_id=eq.\(listId.uuidString.lowercased())" }
        if let itemType { urlStr += "&item_type=eq.\(itemType)" }
        urlStr += "&order=created_at"
        guard let url = URL(string: urlStr) else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([CloudItem].self, from: data)) ?? []
        } catch { return [] }
    }

    func upsertItem(_ item: GroceryItem, listId: UUID? = nil, itemType: String) async {
        guard let token, let userId,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/items") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        req.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")
        var body: [String: Any] = [
            "id":         item.id.uuidString.lowercased(),
            "user_id":    userId,
            "name":       item.name,
            "quantity":   item.quantity,
            "is_checked": item.isChecked,
            "item_type":  itemType,
        ]
        if let listId              { body["list_id"]           = listId.uuidString.lowercased() }
        if let brand = item.brand  { body["brand"]             = brand }
        if let url   = item.imageURL { body["image_url"]       = url }
        if let grade = item.nutriscoreGrade { body["nutriscore_grade"] = grade }
        if let nova  = item.novaGroup       { body["nova_group"]       = nova }
        if let score = item.gistScore       { body["gist_score"]       = score }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await session.data(for: req)
    }

    func deleteItem(id: UUID) async {
        guard let token,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/items?id=eq.\(id.uuidString.lowercased())") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        _ = try? await session.data(for: req)
    }

    // MARK: - Pull on sign-in

    /// Fetches all cloud data and returns it as a tuple for StorageService to apply.
    func pullAll() async -> (lists: [GroceryList], recentlyViewed: [GroceryItem]) {
        async let cloudLists   = fetchLists()
        async let cloudRecent  = fetchItems(listId: nil, itemType: "recently_viewed")

        let (lists, recent) = await (cloudLists, cloudRecent)

        // Build GroceryList array (items fetched per list in parallel)
        var groceryLists: [GroceryList] = []
        await withTaskGroup(of: GroceryList.self) { group in
            for cl in lists {
                group.addTask { [self] in
                    let cloudItems = await self.fetchItems(listId: UUID(uuidString: cl.id), itemType: "list_item")
                    return GroceryList(
                        id:        UUID(uuidString: cl.id) ?? UUID(),
                        name:      cl.name,
                        emoji:     cl.emoji,
                        sortOrder: cl.sortOrder,
                        items:     cloudItems.map { $0.toGroceryItem() }
                    )
                }
            }
            for await list in group { groceryLists.append(list) }
        }
        groceryLists.sort { $0.sortOrder < $1.sortOrder }

        let recentlyViewed = recent.map { $0.toGroceryItem() }
        return (groceryLists, recentlyViewed)
    }
}

// MARK: - Cloud models

struct CloudList: Decodable {
    let id:        String
    let name:      String
    let emoji:     String
    let sortOrder: Int

    enum CodingKeys: String, CodingKey {
        case id, name, emoji
        case sortOrder = "sort_order"
    }
}

struct CloudItem: Decodable {
    let id:               String
    let name:             String
    let brand:            String?
    let imageUrl:         String?
    let nutriscoreGrade:  String?
    let novaGroup:        Int?
    let gistScore:        Int?
    let quantity:         Int
    let isChecked:        Bool
    let itemType:         String

    enum CodingKeys: String, CodingKey {
        case id, name, brand, quantity
        case imageUrl        = "image_url"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup       = "nova_group"
        case gistScore       = "gist_score"
        case isChecked       = "is_checked"
        case itemType        = "item_type"
    }

    func toGroceryItem() -> GroceryItem {
        GroceryItem(
            id:               UUID(uuidString: id) ?? UUID(),
            name:             name,
            brand:            brand,
            imageURL:         imageUrl,
            nutriscoreGrade:  nutriscoreGrade,
            novaGroup:        novaGroup,
            gistScore:        gistScore,
            quantity:         quantity,
            isChecked:        isChecked,
            categoryId:       UUID()
        )
    }
}
