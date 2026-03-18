import Foundation

// MARK: - TursoCloudService
// Drop-in replacement for CloudStorageService.swift when using Turso instead of Supabase.
// Swap by replacing `CloudStorageService.shared` references with `TursoCloudService.shared`.

actor TursoCloudService {
    static let shared = TursoCloudService()

    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private var token:  String? { TursoAuthService.shared.token }
    private var userId: String? { TursoAuthService.shared.profile?.id }

    // MARK: - Lists

    func fetchLists() async -> [CloudList] {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/data?resource=lists") else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([CloudList].self, from: data)) ?? []
        } catch { return [] }
    }

    func upsertList(id: UUID, name: String, emoji: String, sortOrder: Int) async {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/data?resource=lists") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "id": id.uuidString.lowercased(),
            "name": name,
            "color": emoji,   // stored in `color` column — value passed from StorageService
            "sort_order": sortOrder,
        ])
        _ = try? await session.data(for: req)
    }

    func deleteList(id: UUID) async {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/data?resource=lists&id=\(id.uuidString.lowercased())") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        _ = try? await session.data(for: req)
    }

    // MARK: - Items

    func fetchItems(listId: UUID? = nil, itemType: String? = nil) async -> [CloudItem] {
        guard let token else { return [] }
        var urlStr = "\(TursoConfig.apiBase)/api/data?resource=items"
        if let listId   { urlStr += "&list_id=\(listId.uuidString.lowercased())" }
        if let itemType { urlStr += "&item_type=\(itemType)" }
        guard let url = URL(string: urlStr) else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([CloudItem].self, from: data)) ?? []
        } catch { return [] }
    }

    func upsertItem(_ item: GroceryItem, listId: UUID? = nil, itemType: String) async {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/data?resource=items") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        var body: [String: Any] = [
            "id":         item.id.uuidString.lowercased(),
            "name":       item.name,
            "quantity":   item.quantity,
            "is_checked": item.isChecked,
            "item_type":  itemType,
        ]
        if let listId              { body["list_id"]          = listId.uuidString.lowercased() }
        if let brand = item.brand  { body["brand"]            = brand }
        if let url   = item.imageURL { body["image_url"]      = url }
        if let grade = item.nutriscoreGrade { body["nutriscore_grade"] = grade }
        if let nova  = item.novaGroup       { body["nova_group"]       = nova }
        if let score = item.gistScore       { body["gist_score"]       = score }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        _ = try? await session.data(for: req)
    }

    func deleteItem(id: UUID) async {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/data?resource=items&id=\(id.uuidString.lowercased())") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        _ = try? await session.data(for: req)
    }

    // MARK: - Pull on sign-in

    func pullAll() async -> (lists: [GroceryList], recentlyViewed: [GroceryItem]) {
        async let cloudLists  = fetchLists()
        async let cloudRecent = fetchItems(listId: nil, itemType: "recently_viewed")

        let (lists, recent) = await (cloudLists, cloudRecent)

        var groceryLists: [GroceryList] = []
        await withTaskGroup(of: GroceryList.self) { group in
            for cl in lists {
                group.addTask { [self] in
                    let cloudItems = await self.fetchItems(listId: UUID(uuidString: cl.id), itemType: "list_item")
                    return GroceryList(
                        id:        UUID(uuidString: cl.id) ?? UUID(),
                        name:      cl.name,
                        emoji:     cl.color,   // color field maps to emoji slot in the model
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

// MARK: - Cloud models (Turso returns snake_case converted by JSONDecoder)

struct CloudList: Decodable {
    let id:        String
    let name:      String
    let color:     String
    let sortOrder: Int
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
    let isChecked:        Int     // Turso stores booleans as 0/1
    let itemType:         String

    func toGroceryItem() -> GroceryItem {
        GroceryItem(
            id:              UUID(uuidString: id) ?? UUID(),
            name:            name,
            brand:           brand,
            imageURL:        imageUrl,
            nutriscoreGrade: nutriscoreGrade,
            novaGroup:       novaGroup,
            gistScore:       gistScore,
            quantity:        quantity,
            isChecked:       isChecked != 0,
            categoryId:      UUID()
        )
    }
}
