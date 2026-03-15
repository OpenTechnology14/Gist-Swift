import Foundation
import Combine

class OpenFoodFactsService: ObservableObject {
    static let shared = OpenFoodFactsService()

    private var cancellables = Set<AnyCancellable>()

    func searchProducts(query: String) -> AnyPublisher<[Product], Error> {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            return Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
        }
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?search_terms=\(encoded)&search_simple=1&action=process&json=1&page_size=12&fields=product_name,brands,image_front_small_url,nutriscore_grade,nova_group,additives_tags"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .map { response in
                (response.products ?? []).compactMap { $0.toProduct() }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func fetchProduct(barcode: String) -> AnyPublisher<Product?, Error> {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .map { response -> Product? in
                guard response.status == 1 else { return nil }
                return response.product?.toProduct()
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    func discoverProducts(category: String) -> AnyPublisher<[Product], Error> {
        let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?tagtype_0=categories&tag_contains_0=contains&tag_0=\(encoded)&sort_by=unique_scans_n&action=process&json=1&page_size=30&fields=product_name,brands,image_front_small_url,nutriscore_grade,nova_group,additives_tags"
        guard let url = URL(string: urlString) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .map { response in
                (response.products ?? []).compactMap { $0.toProduct() }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    /// async/await variant used by the streaming Discover tab
    func discoverProductsAsync(category: String, pageSize: Int = 30) async -> [Product] {
        let encoded = category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? category
        let urlString = "https://world.openfoodfacts.org/cgi/search.pl?tagtype_0=categories&tag_contains_0=contains&tag_0=\(encoded)&sort_by=unique_scans_n&action=process&json=1&page_size=\(pageSize)&fields=product_name,brands,image_front_small_url,nutriscore_grade,nova_group,additives_tags"
        guard let url = URL(string: urlString) else { return [] }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenFoodFactsResponse.self, from: data)
            let products = (response.products ?? []).compactMap { $0.toProduct() }
            return products.sorted {
                let ga = $0.nutriscoreGrade ?? "z"
                let gb = $1.nutriscoreGrade ?? "z"
                if ga != gb { return ga < gb }
                return ($0.gistScore ?? 0) > ($1.gistScore ?? 0)
            }
        } catch {
            return []
        }
    }
}
