import SwiftUI

struct ProductRow: View {
    let product: Product
    var onAdd: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            // Product image
            AsyncImage(url: URL(string: product.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                default:
                    ProgressView()
                }
            }
            .frame(width: 52, height: 52)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                if let brand = product.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    NutriScoreBadge(grade: product.nutriscoreGrade)
                    NovaBadge(group: product.novaGroup)
                    let highRisk = ScoringService.shared.highRiskAdditives(from: product.additives)
                    AdditiveWarningBadge(count: highRisk.count)
                }
            }

            Spacer()

            VStack(spacing: 6) {
                GistScoreView(score: product.gistScore)

                if let onAdd = onAdd {
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "#7ac94b"))
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct GroceryItemRow: View {
    let item: GroceryItem
    var onToggle: (() -> Void)?
    var onDelete: (() -> Void)?
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onToggle?() }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(item.isChecked ? Color(hex: "#7ac94b") : Color(.systemGray3))
            }

            AsyncImage(url: URL(string: item.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                default:
                    Color(.systemGray6)
                }
            }
            .frame(width: 40, height: 40)
            .background(Color(.systemGray6))
            .cornerRadius(6)
            .clipped()

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
                    .strikethrough(item.isChecked)
                    .foregroundColor(item.isChecked ? .secondary : .primary)
                    .lineLimit(1)
                if let brand = item.brand, !brand.isEmpty {
                    Text(brand)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 4) {
                    NutriScoreBadge(grade: item.nutriscoreGrade)
                    NovaBadge(group: item.novaGroup)
                    let highRisk = ScoringService.shared.highRiskAdditives(from: item.additives)
                    AdditiveWarningBadge(count: highRisk.count)
                }
            }

            Spacer()

            VStack(spacing: 4) {
                GistScoreView(score: item.gistScore)

                HStack(spacing: 4) {
                    Button(action: { onDecrement?() }) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    Text("\(item.quantity)")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(minWidth: 20)
                    Button(action: { onIncrement?() }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "#7ac94b"))
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}
