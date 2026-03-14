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
}
