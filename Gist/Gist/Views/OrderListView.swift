import SwiftUI
import Combine

struct OrderListView: View {
    @EnvironmentObject var storageService: StorageService
    @StateObject private var viewModel = OrderListViewModel()
    @State private var showScanner = false
    @State private var showAddCategory = false
    @State private var selectedCategoryForAdd: GroceryCategory?
    @State private var showCategoryPicker = false
    @State private var pendingProduct: Product?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Text("Order List")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2a2118"))
                    Spacer()
                    Button {
                        showAddCategory = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: "#7ac94b"))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                SearchBar(text: $viewModel.searchQuery, placeholder: "Search products...") {
                    showScanner = true
                }

                if !viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.searchResults) { product in
                                ProductRow(product: product) {
                                    pendingProduct = product
                                    showCategoryPicker = true
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 320)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                } else if viewModel.isLoading {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }

                if storageService.orderItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "bag")
                            .font(.system(size: 56))
                            .foregroundColor(Color(.systemGray4))
                        Text("Your order list is empty")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Search for products or scan a barcode to add items")
                            .font(.subheadline)
                            .foregroundColor(Color(.systemGray3))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(storageService.orderCategories) { category in
                            let items = storageService.orderItems.filter { $0.categoryId == category.id }
                            if !items.isEmpty {
                                Section {
                                    ForEach(items) { item in
                                        GroceryItemRow(
                                            item: item,
                                            onToggle: { storageService.toggleOrderItem(item) },
                                            onDelete: { storageService.removeOrderItem(item) },
                                            onIncrement: {
                                                var updated = item
                                                updated.quantity += 1
                                                storageService.updateOrderItem(updated)
                                            },
                                            onDecrement: {
                                                if item.quantity > 1 {
                                                    var updated = item
                                                    updated.quantity -= 1
                                                    storageService.updateOrderItem(updated)
                                                } else {
                                                    storageService.removeOrderItem(item)
                                                }
                                            }
                                        )
                                        .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                storageService.removeOrderItem(item)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    }
                                } header: {
                                    HStack {
                                        Image(systemName: category.iconName)
                                            .font(.system(size: 13))
                                            .foregroundColor(Color(hex: "#7ac94b"))
                                        Text(category.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(Color(hex: "#2a2118"))
                                        Spacer()
                                        Text("\(items.count)")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showScanner) {
            BarcodeScannerView(scannedCode: $viewModel.scannedBarcode, isPresented: $showScanner)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $showAddCategory) {
            AddCategorySheet(isPresented: $showAddCategory) { name in
                let cat = GroceryCategory(
                    name: name,
                    iconName: "tag.fill",
                    sortOrder: storageService.orderCategories.count
                )
                storageService.addOrderCategory(cat)
            }
        }
        .sheet(isPresented: $showCategoryPicker) {
            if let product = pendingProduct {
                CategoryPickerSheet(
                    categories: storageService.orderCategories,
                    isPresented: $showCategoryPicker
                ) { category in
                    let item = GroceryItem(from: product, categoryId: category.id)
                    storageService.addToOrder(item)
                    viewModel.searchQuery = ""
                }
            }
        }
        .onChange(of: viewModel.scannedBarcode) { _, barcode in
            if let code = barcode {
                viewModel.lookupBarcode(code)
            }
        }
        .onChange(of: viewModel.scannedProduct) { _, product in
            if let p = product {
                pendingProduct = p
                showCategoryPicker = true
                viewModel.scannedProduct = nil
                viewModel.scannedBarcode = nil
            }
        }
    }
}

class OrderListViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Product] = []
    @Published var isLoading = false
    @Published var scannedBarcode: String?
    @Published var scannedProduct: Product?

    private var cancellables = Set<AnyCancellable>()
    private let service = OpenFoodFactsService.shared

    init() {
        $searchQuery
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .handleEvents(receiveOutput: { [weak self] query in
                if query.isEmpty { self?.searchResults = [] }
                self?.isLoading = !query.isEmpty
            })
            .filter { !$0.isEmpty }
            .map { [weak self] query -> AnyPublisher<[Product], Never> in
                guard let self else { return Just([]).eraseToAnyPublisher() }
                return self.service.searchProducts(query: query)
                    .replaceError(with: [])
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.searchResults = products
                self?.isLoading = false
            }
            .store(in: &cancellables)
    }

    func lookupBarcode(_ code: String) {
        isLoading = true
        service.fetchProduct(barcode: code)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] product in
                self?.scannedProduct = product
                self?.isLoading = false
            })
            .store(in: &cancellables)
    }
}
