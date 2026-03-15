import Foundation
import Combine

class OpenFoodFactsService: ObservableObject {
    static let shared = OpenFoodFactsService()

    // Dedicated session: 50 MB memory / 200 MB disk cache, 10 s timeout
    private let session: URLSession = {
        let cache = URLCache(
            memoryCapacity:  50 * 1024 * 1024,
            diskCapacity:   200 * 1024 * 1024
        )
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 10
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()

    // In-memory search cache keyed by normalised query string
    private var searchCache = NSCache<NSString, NSArray>()
    private let decoder = JSONDecoder()
    private let offFields = "product_name,brands,image_front_small_url,nutriscore_grade,nova_group,additives_tags"

    // MARK: - Search

    func searchProducts(query: String) -> AnyPublisher<[Product], Error> {
        let key = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        if let cached = searchCache.object(forKey: key as NSString) as? [Product] {
            return Just(cached).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        guard let url = searchURL(for: key) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: decoder)
            .map { [weak self] response -> [Product] in
                let products = (response.products ?? []).compactMap { $0.toProduct() }
                self?.searchCache.setObject(products as NSArray, forKey: key as NSString)
                return products
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Barcode

    func fetchProduct(barcode: String) -> AnyPublisher<Product?, Error> {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: decoder)
            .map { response -> Product? in
                guard response.status == 1 else { return nil }
                return response.product?.toProduct()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchProductAsync(barcode: String) async -> Product? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(barcode).json") else { return nil }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try decoder.decode(OpenFoodFactsResponse.self, from: data)
            guard response.status == 1 else { return nil }
            return response.product?.toProduct()
        } catch { return nil }
    }

    // MARK: - Discover (async, used by DiscoverViewModel task group)

    func discoverProductsAsync(category: String, pageSize: Int = 20) async -> [Product] {
        guard let url = discoverURL(for: category, pageSize: pageSize) else { return [] }
        do {
            let (data, _) = try await session.data(from: url)
            let response = try decoder.decode(OpenFoodFactsResponse.self, from: data)
            return (response.products ?? [])
                .compactMap { $0.toProduct() }
                .sorted {
                    let ga = $0.nutriscoreGrade ?? "z"
                    let gb = $1.nutriscoreGrade ?? "z"
                    if ga != gb { return ga < gb }
                    return ($0.gistScore ?? 0) > ($1.gistScore ?? 0)
                }
        } catch { return [] }
    }

    // MARK: - URL builders

    private func searchURL(for query: String) -> URL? {
        var c = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        c.queryItems = [
            .init(name: "search_terms",  value: query),
            .init(name: "search_simple", value: "1"),
            .init(name: "action",        value: "process"),
            .init(name: "json",          value: "1"),
            .init(name: "page_size",     value: "8"),
            .init(name: "fields",        value: offFields),
        ]
        return c.url
    }

    private func discoverURL(for category: String, pageSize: Int) -> URL? {
        var c = URLComponents(string: "https://world.openfoodfacts.org/cgi/search.pl")!
        c.queryItems = [
            .init(name: "tagtype_0",      value: "categories"),
            .init(name: "tag_contains_0", value: "contains"),
            .init(name: "tag_0",          value: category),
            .init(name: "sort_by",        value: "unique_scans_n"),
            .init(name: "action",         value: "process"),
            .init(name: "json",           value: "1"),
            .init(name: "page_size",      value: "\(pageSize)"),
            .init(name: "fields",         value: offFields),
        ]
        return c.url
    }
}
