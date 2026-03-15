import Foundation

struct GroceryItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var brand: String?
    var imageURL: String?
    var nutriscoreGrade: String?
    var novaGroup: Int?
    var gistScore: Int?
    var additives: [AdditiveRisk]
    var categoryId: UUID
    var isChecked: Bool = false
    var quantity: Int = 1

    init(from product: Product, categoryId: UUID) {
        self.name = product.name
        self.brand = product.brand
        self.imageURL = product.imageURL
        self.nutriscoreGrade = product.nutriscoreGrade
        self.novaGroup = product.novaGroup
        self.gistScore = product.gistScore
        self.additives = product.additives
        self.categoryId = categoryId
    }

    init(name: String, categoryId: UUID) {
        self.name = name
        self.categoryId = categoryId
        self.additives = []
    }

    /// Used by CloudStorageService to reconstruct items with their cloud UUID.
    init(id: UUID, name: String, brand: String? = nil, imageURL: String? = nil,
         nutriscoreGrade: String? = nil, novaGroup: Int? = nil, gistScore: Int? = nil,
         quantity: Int = 1, isChecked: Bool = false, categoryId: UUID) {
        self.id = id
        self.name = name
        self.brand = brand
        self.imageURL = imageURL
        self.nutriscoreGrade = nutriscoreGrade
        self.novaGroup = novaGroup
        self.gistScore = gistScore
        self.quantity = quantity
        self.isChecked = isChecked
        self.categoryId = categoryId
        self.additives = []
    }
}
