import SwiftUI
import Combine

struct DiscoverView: View {
    @EnvironmentObject var storageService: StorageService
    @StateObject private var viewModel = DiscoverViewModel()
    @State private var showCategoryPicker = false
    @State private var pendingProduct: Product?
    @State private var targetList: TargetList = .grocery

    enum TargetList { case grocery, order }

    let discoverCategories = ["Fruits", "Vegetables", "Dairy", "Snacks", "Beverages", "Cereals", "Meat", "Fish"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Discover")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2a2118"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(discoverCategories, id: \.self) { category in
                            Button {
                                viewModel.selectCategory(category)
                            } label: {
                                Text(category)
                                    .font(.system(size: 14, weight: .medium))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(viewModel.selectedCategory == category
                                        ? Color(hex: "#2a2118")
                                        : Color(.systemGray6))
                                    .foregroundColor(viewModel.selectedCategory == category
                                        ? .white
                                        : Color(hex: "#2a2118"))
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 12)

                if viewModel.isLoading {
                    Spacer()
                    ProgressView("Loading products...")
                        .foregroundColor(.secondary)
                    Spacer()
                } else if viewModel.products.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 56))
                            .foregroundColor(Color(.systemGray4))
                        Text("Select a category to discover top products")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(viewModel.products) { product in
                                DiscoverProductCard(product: product) { list in
                                    pendingProduct = product
                                    targetList = list
                                    showCategoryPicker = true
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showCategoryPicker) {
            if let product = pendingProduct {
                let categories = targetList == .grocery
                    ? storageService.groceryCategories
                    : storageService.orderCategories
                CategoryPickerSheet(
                    categories: categories,
                    isPresented: $showCategoryPicker
                ) { category in
                    let item = GroceryItem(from: product, categoryId: category.id)
                    if targetList == .grocery {
                        storageService.addToGrocery(item)
                    } else {
                        storageService.addToOrder(item)
                    }
                }
            }
        }
    }
}

struct DiscoverProductCard: View {
    let product: Product
    var onAdd: ((DiscoverView.TargetList) -> Void)?
    @State private var showDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
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
                .frame(width: 64, height: 64)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.name)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(2)
                    if let brand = product.brand, !brand.isEmpty {
                        Text(brand)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    HStack(spacing: 4) {
                        NutriScoreBadge(grade: product.nutriscoreGrade)
                        NovaBadge(group: product.novaGroup)
                        let highRisk = ScoringService.shared.highRiskAdditives(from: product.additives)
                        AdditiveWarningBadge(count: highRisk.count)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    GistScoreView(score: product.gistScore)
                    Menu {
                        Button {
                            onAdd?(.grocery)
                        } label: {
                            Label("Add to Grocery", systemImage: "cart.badge.plus")
                        }
                        Button {
                            onAdd?(.order)
                        } label: {
                            Label("Add to Order", systemImage: "bag.badge.plus")
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 26))
                            .foregroundColor(Color(hex: "#7ac94b"))
                    }
                }
            }
            .padding(12)

            if showDetail {
                GistScoreDetailView(score: product.gistScore, additives: product.additives)
                    .padding([.horizontal, .bottom], 12)
            }

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showDetail.toggle()
                }
            } label: {
                HStack {
                    Text(showDetail ? "Hide details" : "View health details")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#7ac94b"))
                    Image(systemName: showDetail ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "#7ac94b"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.07), radius: 6, x: 0, y: 3)
    }
}

class DiscoverViewModel: ObservableObject {
    @Published var selectedCategory: String?
    @Published var products: [Product] = []
    @Published var isLoading = false

    private var cancellables = Set<AnyCancellable>()
    private let service = OpenFoodFactsService.shared

    func selectCategory(_ category: String) {
        selectedCategory = category
        isLoading = true
        products = []
        service.discoverProducts(category: category.lowercased())
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] products in
                self?.products = products
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
}
