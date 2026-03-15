import SwiftUI
import Combine

// ─── Data Types ───────────────────────────────────────────────────────────────

struct DiscoverCat: Identifiable {
    let id: String
    let label: String
    let emoji: String
    let tag: String
    let gradientColors: [Color]
}

struct DiscoverItem: Identifiable {
    let id = UUID()
    let product: Product
    let cat: DiscoverCat
}

// ─── Category Data ────────────────────────────────────────────────────────────

private let groceryCats: [DiscoverCat] = [
    DiscoverCat(id: "meat",       label: "Meat",       emoji: "🥩", tag: "en:meats",           gradientColors: [Color(hex: "#c0392b"), Color(hex: "#e74c3c")]),
    DiscoverCat(id: "desserts",   label: "Desserts",   emoji: "🍰", tag: "en:desserts",         gradientColors: [Color(hex: "#8e44ad"), Color(hex: "#e056d7")]),
    DiscoverCat(id: "vegetables", label: "Vegetables", emoji: "🥦", tag: "en:vegetables",       gradientColors: [Color(hex: "#1a9e3f"), Color(hex: "#7ac94b")]),
    DiscoverCat(id: "fruits",     label: "Fruits",     emoji: "🍎", tag: "en:fruits",           gradientColors: [Color(hex: "#e67e22"), Color(hex: "#f39c12")]),
    DiscoverCat(id: "drinks",     label: "Drinks",     emoji: "🥤", tag: "en:beverages",        gradientColors: [Color(hex: "#2980b9"), Color(hex: "#3498db")]),
    DiscoverCat(id: "bread",      label: "Bread",      emoji: "🍞", tag: "en:breads",           gradientColors: [Color(hex: "#d35400"), Color(hex: "#e67e22")]),
    DiscoverCat(id: "dairy",      label: "Dairy",      emoji: "🧀", tag: "en:dairy-products",   gradientColors: [Color(hex: "#f39c12"), Color(hex: "#f1c40f")]),
    DiscoverCat(id: "frozen",     label: "Frozen",     emoji: "❄️", tag: "en:frozen-foods",     gradientColors: [Color(hex: "#2471a3"), Color(hex: "#5dade2")]),
    DiscoverCat(id: "dips",       label: "Dips",       emoji: "🫙", tag: "en:dips",             gradientColors: [Color(hex: "#7d6608"), Color(hex: "#d4ac0d")]),
    DiscoverCat(id: "store",      label: "Store",      emoji: "🏪", tag: "en:groceries",        gradientColors: [Color(hex: "#555555"), Color(hex: "#888888")]),
]

private let orderCats: [DiscoverCat] = [
    DiscoverCat(id: "snacks",      label: "Snacks",      emoji: "🍿", tag: "en:snacks",           gradientColors: [Color(hex: "#e67e22"), Color(hex: "#f39c12")]),
    DiscoverCat(id: "baking",      label: "Baking",      emoji: "🎂", tag: "en:baking",           gradientColors: [Color(hex: "#8e44ad"), Color(hex: "#9b59b6")]),
    DiscoverCat(id: "sauces",      label: "Sauces",      emoji: "🍅", tag: "en:sauces",           gradientColors: [Color(hex: "#c0392b"), Color(hex: "#e74c3c")]),
    DiscoverCat(id: "canned",      label: "Canned",      emoji: "🥫", tag: "en:canned-foods",     gradientColors: [Color(hex: "#7d6608"), Color(hex: "#d4ac0d")]),
    DiscoverCat(id: "seasonings",  label: "Seasonings",  emoji: "🧂", tag: "en:seasonings",       gradientColors: [Color(hex: "#555555"), Color(hex: "#888888")]),
    DiscoverCat(id: "hair",        label: "Hair",        emoji: "💇", tag: "en:hair-care",        gradientColors: [Color(hex: "#8e44ad"), Color(hex: "#e056d7")]),
    DiscoverCat(id: "bodywash",    label: "Body Wash",   emoji: "🚿", tag: "en:body-washes",      gradientColors: [Color(hex: "#2980b9"), Color(hex: "#3498db")]),
    DiscoverCat(id: "moisturizer", label: "Moisturizer", emoji: "🧴", tag: "en:moisturizers",     gradientColors: [Color(hex: "#1a9e3f"), Color(hex: "#7ac94b")]),
    DiscoverCat(id: "naturals",    label: "Naturals",    emoji: "🌿", tag: "en:organic-products", gradientColors: [Color(hex: "#1a9e3f"), Color(hex: "#2ecc71")]),
    DiscoverCat(id: "other",       label: "Other",       emoji: "📦", tag: "en:groceries",        gradientColors: [Color(hex: "#7f8c8d"), Color(hex: "#95a5a6")]),
]

// ─── ViewModel ────────────────────────────────────────────────────────────────

@MainActor
class DiscoverViewModel: ObservableObject {
    @Published var items: [DiscoverItem] = []
    @Published var loadingCount: Int = 0
    @Published var activeToggle: String = "grocery"
    @Published var activeFilters: Set<String> = []

    private var cache: [String: [Product]] = [:]
    private var currentTask: Task<Void, Never>?

    var isLoading: Bool { loadingCount > 0 }
    var currentCats: [DiscoverCat] { activeToggle == "grocery" ? groceryCats : orderCats }
    var selectedCats: [DiscoverCat] {
        activeFilters.isEmpty ? currentCats : currentCats.filter { activeFilters.contains($0.id) }
    }

    func switchToggle(_ value: String) {
        activeToggle = value
        activeFilters = []
        reload()
    }

    func toggleFilter(_ id: String) {
        if activeFilters.contains(id) { activeFilters.remove(id) }
        else { activeFilters.insert(id) }
        reload()
    }

    func reload() {
        currentTask?.cancel()
        items = []
        let cats = selectedCats
        let isAllMode = activeFilters.isEmpty
        let pageSize = isAllMode ? 8 : 30
        let maxPerCat = isAllMode ? 1 : 10
        loadingCount = cats.count

        currentTask = Task {
            await withTaskGroup(of: (DiscoverCat, [Product]).self) { group in
                for cat in cats {
                    let cacheKey = "\(cat.tag):\(pageSize)"
                    let hit = cache[cacheKey]
                    group.addTask { [weak self] in
                        if let cached = hit {
                            return (cat, Array(cached.prefix(maxPerCat)))
                        }
                        let products = await OpenFoodFactsService.shared
                            .discoverProductsAsync(category: cat.tag, pageSize: pageSize)
                        await MainActor.run { self?.cache[cacheKey] = products }
                        return (cat, Array(products.prefix(maxPerCat)))
                    }
                }
                for await (cat, products) in group {
                    guard !Task.isCancelled else { break }
                    loadingCount = max(0, loadingCount - 1)
                    let newItems = products.map { DiscoverItem(product: $0, cat: cat) }
                    withAnimation(.easeOut(duration: 0.28)) {
                        items.append(contentsOf: newItems)
                    }
                }
            }
        }
    }
}

// ─── Main View ────────────────────────────────────────────────────────────────

struct DiscoverView: View {
    @EnvironmentObject var storageService: StorageService
    @StateObject private var viewModel = DiscoverViewModel()

    var body: some View {
        VStack(spacing: 0) {

            // iOS-style nav title bar
            HStack {
                Text("✨ Discover")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background(.ultraThinMaterial)
            .overlay(alignment: .bottom) { Divider() }

            // Sticky filter header
            VStack(spacing: 0) {
                // Grocery / Order segmented control
                Picker("Type", selection: Binding(
                    get: { viewModel.activeToggle },
                    set: { viewModel.switchToggle($0) }
                )) {
                    Text("🛒 Grocery").tag("grocery")
                    Text("📦 Order").tag("order")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Category filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.currentCats) { cat in
                            let on = viewModel.activeFilters.contains(cat.id)
                            Button { viewModel.toggleFilter(cat.id) } label: {
                                HStack(spacing: 4) {
                                    Text(cat.emoji).font(.system(size: 12))
                                    Text(cat.label)
                                        .font(.system(size: 12, weight: on ? .semibold : .regular))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    on
                                    ? LinearGradient(
                                        colors: cat.gradientColors,
                                        startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient(
                                        colors: [Color(.systemGray5), Color(.systemGray5)],
                                        startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(on ? .white : .primary)
                                .clipShape(Capsule())
                                .animation(.easeInOut(duration: 0.15), value: on)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 10)
            }
            .background(Color(.systemBackground))
            .overlay(alignment: .bottom) { Divider() }

            // Status label
            HStack(spacing: 4) {
                Text(viewModel.activeFilters.isEmpty
                    ? "Top pick from each \(viewModel.activeToggle) category"
                    : "\(viewModel.activeFilters.count) filter\(viewModel.activeFilters.count > 1 ? "s" : "") active")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                if viewModel.isLoading {
                    Text("· Loading…")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "#34c759"))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)

            // Product list
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(viewModel.items) { item in
                        DiscoverProductCard(
                            product: item.product,
                            cat: item.cat,
                            onExpand: {
                                storageService.addToRecentlyViewed(from: item.product)
                            }
                        )
                        .padding(.horizontal, 16)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .bottom)),
                            removal: .opacity
                        ))
                    }

                    // Skeleton placeholders while loading initial items
                    if viewModel.items.isEmpty && viewModel.isLoading {
                        ForEach(0..<5, id: \.self) { _ in
                            DiscoverSkeletonCard()
                                .padding(.horizontal, 16)
                        }
                    }

                    // Empty state
                    if viewModel.items.isEmpty && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 48))
                                .foregroundColor(Color(.systemGray4))
                            Text("No products found")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    }
                }
                .padding(.vertical, 8)
                .animation(.easeOut(duration: 0.25), value: viewModel.items.count)
            }
        }
        .onAppear { viewModel.reload() }
    }
}

// ─── Product Card ─────────────────────────────────────────────────────────────

struct DiscoverProductCard: View {
    let product: Product
    let cat: DiscoverCat
    var onExpand: (() -> Void)?

    @State private var expanded = false
    @State private var addedToRecent = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            // Tappable header row — tap to expand; first expand adds to Recently Viewed
            Button {
                withAnimation(.easeInOut(duration: 0.22)) {
                    expanded.toggle()
                    if expanded && !addedToRecent {
                        addedToRecent = true
                        onExpand?()
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    // Squircle product image
                    Group {
                        if let urlStr = product.imageURL, let url = URL(string: urlStr) {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let img):
                                    img.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    ZStack {
                                        LinearGradient(
                                            colors: cat.gradientColors,
                                            startPoint: .topLeading, endPoint: .bottomTrailing)
                                        Text(cat.emoji).font(.system(size: 22))
                                    }
                                default:
                                    Color(.systemGray6).overlay(ProgressView())
                                }
                            }
                        } else {
                            LinearGradient(
                                colors: cat.gradientColors,
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            .overlay(Text(cat.emoji).font(.system(size: 24)))
                        }
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(
                        cornerRadius: 60 * 0.3125, style: .continuous))
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 0, y: 1)

                    // Name + brand + badges
                    VStack(alignment: .leading, spacing: 4) {
                        Text(product.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)
                        if let brand = product.brand, !brand.isEmpty {
                            Text(brand)
                                .font(.system(size: 11))
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

                    // Gist score ring + chevron
                    VStack(spacing: 6) {
                        GistScoreView(score: product.gistScore)
                        Image(systemName: expanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            // Expanded detail section
            if expanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.horizontal, 14)

                    GistScoreDetailView(
                        score: product.gistScore,
                        additives: product.additives
                    )
                    .padding(.horizontal, 14)

                    // "Added to Recently Viewed" confirmation pill
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: "#34c759"))
                        Text("Added to Recently Viewed")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color(hex: "#34c759"))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

// ─── Skeleton Card ────────────────────────────────────────────────────────────

struct DiscoverSkeletonCard: View {
    @State private var animate = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 60 * 0.3125, style: .continuous)
                .frame(width: 60, height: 60)
                .foregroundColor(Color(.systemGray5))
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 14)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(Color(.systemGray5))
                RoundedRectangle(cornerRadius: 4)
                    .frame(height: 11)
                    .frame(maxWidth: 110)
                    .foregroundColor(Color(.systemGray6))
            }
            Spacer()
        }
        .padding(14)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .opacity(animate ? 0.45 : 1.0)
        .animation(
            .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear { animate = true }
    }
}
