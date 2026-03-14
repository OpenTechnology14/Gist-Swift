import Foundation

struct AdditiveRisk: Codable, Identifiable {
    var id: String
    var riskLevel: Int
    var name: String
}

struct Product: Identifiable {
    var id = UUID()
    var name: String
    var brand: String?
    var imageURL: String?
    var nutriscoreGrade: String?
    var novaGroup: Int?
    var additivesTags: [String]
    var gistScore: Int?
    var additives: [AdditiveRisk]

    init(name: String, brand: String? = nil, imageURL: String? = nil,
         nutriscoreGrade: String? = nil, novaGroup: Int? = nil,
         additivesTags: [String] = []) {
        self.name = name
        self.brand = brand
        self.imageURL = imageURL
        self.nutriscoreGrade = nutriscoreGrade
        self.novaGroup = novaGroup
        self.additivesTags = additivesTags
        self.additives = ScoringService.shared.parseAdditives(from: additivesTags)
        self.gistScore = ScoringService.shared.calculateGistScore(
            nutriscoreGrade: nutriscoreGrade,
            additives: self.additives
        )
    }
}

struct OpenFoodFactsResponse: Codable {
    let products: [OpenFoodFactsProduct]?
    let product: OpenFoodFactsProduct?
    let status: Int?
}

struct OpenFoodFactsProduct: Codable {
    let productName: String?
    let brands: String?
    let imageFrontSmallUrl: String?
    let nutriscoreGrade: String?
    let novaGroup: Int?
    let additivesTags: [String]?

    enum CodingKeys: String, CodingKey {
        case productName = "product_name"
        case brands
        case imageFrontSmallUrl = "image_front_small_url"
        case nutriscoreGrade = "nutriscore_grade"
        case novaGroup = "nova_group"
        case additivesTags = "additives_tags"
    }

    func toProduct() -> Product? {
        guard let name = productName, !name.isEmpty else { return nil }
        return Product(
            name: name,
            brand: brands,
            imageURL: imageFrontSmallUrl,
            nutriscoreGrade: nutriscoreGrade?.lowercased(),
            novaGroup: novaGroup,
            additivesTags: additivesTags ?? []
        )
    }
}
