import SwiftUI
import Combine

struct GroceryListView: View {
    @EnvironmentObject var storageService: StorageService
    @StateObject private var viewModel = GroceryListViewModel()
    @State private var showScanner = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Gist")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2a2118"))
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)

                SearchBar(
                    text: $viewModel.searchQuery,
                    placeholder: "Search groceries...",
                    onScanTap: { showScanner = true },
                    suggestion: "Taco Tuesday",
                    onSuggestionTap: { viewModel.searchQuery = "Taco Tuesday" }
                )

                // Search results dropdown
                if !viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.searchResults) { product in
                                ProductRow(product: product) {
                                    let defaultCategoryId = storageService.groceryCategories.first?.id ?? UUID()
                                    let item = GroceryItem(from: product, categoryId: defaultCategoryId)
                                    storageService.addToGrocery(item)
                                    viewModel.searchQuery = ""
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

                // Flat grocery list
                if storageService.groceryItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 56))
                            .foregroundColor(Color(.systemGray4))
                        Text("Your grocery list is empty")
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
                        ForEach(storageService.groceryItems) { item in
                            GroceryItemRow(
                                item: item,
                                onToggle: { storageService.toggleGroceryItem(item) },
                                onDelete: { storageService.removeGroceryItem(item) },
                                onIncrement: {
                                    var updated = item
                                    updated.quantity += 1
                                    storageService.updateGroceryItem(updated)
                                },
                                onDecrement: {
                                    if item.quantity > 1 {
                                        var updated = item
                                        updated.quantity -= 1
                                        storageService.updateGroceryItem(updated)
                                    } else {
                                        storageService.removeGroceryItem(item)
                                    }
                                }
                            )
                            .listRowInsets(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    storageService.removeGroceryItem(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
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
        .onChange(of: viewModel.scannedBarcode) { _, barcode in
            if let code = barcode {
                viewModel.lookupBarcode(code)
            }
        }
        .onChange(of: viewModel.scannedProduct) { _, product in
            if let p = product {
                let defaultCategoryId = storageService.groceryCategories.first?.id ?? UUID()
                let item = GroceryItem(from: p, categoryId: defaultCategoryId)
                storageService.addToGrocery(item)
                viewModel.scannedProduct = nil
                viewModel.scannedBarcode = nil
            }
        }
    }
}

class GroceryListViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Product] = []
    @Published var isLoading = false
    @Published var scannedBarcode: String?
    @Published var scannedProduct: Product?

    private var cancellables = Set<AnyCancellable>()
    private let service = OpenFoodFactsService.shared

    init() {
        $searchQuery
            .debounce(for: .milliseconds(400), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.searchResults = []
                } else {
                    self?.search(query: query)
                }
            }
            .store(in: &cancellables)
    }

    private func search(query: String) {
        isLoading = true
        service.searchProducts(query: query)
            .sink(receiveCompletion: { [weak self] _ in
                self?.isLoading = false
            }, receiveValue: { [weak self] products in
                self?.searchResults = products
                self?.isLoading = false
            })
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

struct AddCategorySheet: View {
    @Binding var isPresented: Bool
    var onAdd: (String) -> Void
    @State private var name = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Category Name") {
                    TextField("e.g. Organic, Baby Food...", text: $name)
                }
            }
            .navigationTitle("New Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if !name.isEmpty {
                            onAdd(name)
                            isPresented = false
                        }
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct CategoryPickerSheet: View {
    let categories: [GroceryCategory]
    @Binding var isPresented: Bool
    var onSelect: (GroceryCategory) -> Void

    var body: some View {
        NavigationStack {
            List(categories) { category in
                Button {
                    onSelect(category)
                    isPresented = false
                } label: {
                    HStack {
                        Image(systemName: category.iconName)
                            .foregroundColor(Color(hex: "#7ac94b"))
                            .frame(width: 28)
                        Text(category.name)
                            .foregroundColor(.primary)
                    }
                }
            }
            .navigationTitle("Add to Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
