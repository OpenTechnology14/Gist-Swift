import SwiftUI
import Combine

// MARK: - Main Lists View

struct ListsView: View {
    @EnvironmentObject var storageService: StorageService
    @StateObject private var viewModel = ListsViewModel()
    @State private var showAddList = false
    @State private var moveItem: GroceryItem?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Gist")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "#2a2118"))
                    Spacer()
                    EditButton()
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(hex: "#7ac94b"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // Search bar — below header, not covering window
                SearchBar(
                    text: $viewModel.searchQuery,
                    placeholder: "Search products...",
                    onScanTap: nil,
                    suggestion: "Taco Tuesday",
                    onSuggestionTap: { viewModel.searchQuery = "Taco Tuesday" }
                )

                // Inline search results — scroll within fixed height, no overlay
                if viewModel.isLoading && !viewModel.searchQuery.isEmpty {
                    HStack {
                        ProgressView()
                        Text("Searching...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 10)
                } else if !viewModel.searchResults.isEmpty && !viewModel.searchQuery.isEmpty {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(viewModel.searchResults) { product in
                                Button {
                                    storageService.addToRecentlyViewed(from: product)
                                    viewModel.searchQuery = ""
                                } label: {
                                    HStack(spacing: 12) {
                                        AsyncImage(url: URL(string: product.imageURL ?? "")) { phase in
                                            switch phase {
                                            case .success(let img):
                                                img.resizable().aspectRatio(contentMode: .fill)
                                            default:
                                                Color(.systemGray6)
                                            }
                                        }
                                        .frame(width: 38, height: 38)
                                        .cornerRadius(6)
                                        .clipped()

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(product.name)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            if let brand = product.brand, !brand.isEmpty {
                                                Text(brand)
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                        }

                                        Spacer()

                                        NutriScoreBadge(grade: product.nutriscoreGrade)
                                    }
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 9)
                                }
                                .buttonStyle(.plain)

                                Divider().padding(.leading, 66)
                            }
                        }
                    }
                    .frame(maxHeight: 260)
                    .background(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                }

                // Main list
                List {
                    // New List button
                    Button {
                        showAddList = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: "#7ac94b").opacity(0.12))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "plus")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color(hex: "#7ac94b"))
                            }
                            Text("New List")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(Color(hex: "#7ac94b"))
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                    .listRowSeparator(.hidden)
                    .deleteDisabled(true)
                    .moveDisabled(true)

                    // User-created lists (reorderable, deletable)
                    ForEach(storageService.groceryLists) { list in
                        ListCardRow(listId: list.id)
                    }
                    .onMove { storageService.reorderGroceryLists(from: $0, to: $1) }
                    .onDelete { storageService.removeGroceryList(at: $0) }

                    // Recently Viewed section
                    Section {
                        if storageService.recentlyViewed.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 10) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 34))
                                        .foregroundColor(Color(.systemGray4))
                                    Text("Search for products above to view them here")
                                        .font(.caption)
                                        .foregroundColor(Color(.systemGray3))
                                        .multilineTextAlignment(.center)
                                }
                                .padding(.vertical, 24)
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .deleteDisabled(true)
                            .moveDisabled(true)
                        } else {
                            ForEach(storageService.recentlyViewed) { item in
                                RecentlyViewedRow(item: item) {
                                    moveItem = item
                                }
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .listRowSeparator(.hidden)
                                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                    Button {
                                        moveItem = item
                                    } label: {
                                        Label("Move to List", systemImage: "arrow.right.circle.fill")
                                    }
                                    .tint(Color(hex: "#7ac94b"))
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        storageService.removeFromRecentlyViewed(item)
                                    } label: {
                                        Label("Remove", systemImage: "trash")
                                    }
                                }
                                .moveDisabled(true)
                            }
                        }
                    } header: {
                        Text("Recently Viewed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .textCase(nil)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddList) {
            AddListSheet(isPresented: $showAddList) { name, emoji in
                storageService.addGroceryList(name: name, emoji: emoji)
            }
        }
        .sheet(item: $moveItem) { item in
            MoveToListSheet(item: item, lists: storageService.groceryLists) {
                moveItem = nil
            } onSelect: { list in
                storageService.moveToList(item: item, listId: list.id)
                moveItem = nil
            }
        }
    }
}

// MARK: - List Card Row

struct ListCardRow: View {
    let listId: UUID
    @EnvironmentObject var storageService: StorageService
    @State private var isExpanded = false

    var list: GroceryList? {
        storageService.groceryLists.first(where: { $0.id == listId })
    }

    var body: some View {
        if let list = list {
            DisclosureGroup(isExpanded: $isExpanded) {
                if list.items.isEmpty {
                    Text("No items yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 10)
                        .listRowSeparator(.hidden)
                        .deleteDisabled(true)
                        .moveDisabled(true)
                } else {
                    ForEach(list.items) { item in
                        GroceryItemRow(
                            item: item,
                            onToggle: { storageService.toggleItemInList(item: item, listId: list.id) },
                            onDelete: { storageService.removeItemFromList(item: item, listId: list.id) },
                            onIncrement: {
                                var updated = item
                                updated.quantity += 1
                                storageService.updateItemInList(item: updated, listId: list.id)
                            },
                            onDecrement: {
                                if item.quantity > 1 {
                                    var updated = item
                                    updated.quantity -= 1
                                    storageService.updateItemInList(item: updated, listId: list.id)
                                } else {
                                    storageService.removeItemFromList(item: item, listId: list.id)
                                }
                            }
                        )
                        .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 16))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                storageService.removeItemFromList(item: item, listId: list.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .moveDisabled(true)
                    }
                }
            } label: {
                HStack(spacing: 12) {
                    Text(list.emoji)
                        .font(.system(size: 26))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(list.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("\(list.items.count) item\(list.items.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
        }
    }
}

// MARK: - Recently Viewed Row

struct RecentlyViewedRow: View {
    let item: GroceryItem
    var onMoveToList: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: item.imageURL ?? "")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    Image(systemName: "photo").foregroundColor(.secondary)
                default:
                    Color(.systemGray6)
                }
            }
            .frame(width: 42, height: 42)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .clipped()

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 14, weight: .medium))
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
                }
            }

            Spacer()

            GistScoreView(score: item.gistScore)

            Button(action: { onMoveToList?() }) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "#7ac94b"))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Add List Sheet

struct AddListSheet: View {
    @Binding var isPresented: Bool
    var onAdd: (String, String) -> Void

    @State private var name = ""
    @State private var selectedEmoji = "🛒"

    let emojis = [
        "🛒", "🏪", "🥗", "🍽️", "🏠", "💊", "🎁", "📦",
        "🧴", "🥩", "🥦", "🍎", "🧀", "🍞", "🥤", "❄️"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section("List Name") {
                    TextField("e.g. Weekly Groceries...", text: $name)
                }
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                        ForEach(emojis, id: \.self) { emoji in
                            Button {
                                selectedEmoji = emoji
                            } label: {
                                Text(emoji)
                                    .font(.system(size: 26))
                                    .padding(6)
                                    .background(
                                        selectedEmoji == emoji
                                            ? Color(hex: "#7ac94b").opacity(0.2)
                                            : Color.clear
                                    )
                                    .cornerRadius(8)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        if !name.isEmpty {
                            onAdd(name, selectedEmoji)
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

// MARK: - Move To List Sheet

struct MoveToListSheet: View {
    @Environment(\.dismiss) var dismiss
    let item: GroceryItem
    let lists: [GroceryList]
    var onDismiss: (() -> Void)?
    var onSelect: (GroceryList) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 48))
                            .foregroundColor(Color(.systemGray4))
                        Text("No lists yet")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Tap \"New List\" on the main screen to create one.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(lists) { list in
                        Button {
                            onSelect(list)
                        } label: {
                            HStack(spacing: 14) {
                                Text(list.emoji)
                                    .font(.system(size: 26))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(list.name)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(.primary)
                                    Text("\(list.items.count) item\(list.items.count == 1 ? "" : "s")")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundColor(Color(hex: "#7ac94b"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add \"\(item.name)\"")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onDismiss?(); dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - View Model

class ListsViewModel: ObservableObject {
    @Published var searchQuery = ""
    @Published var searchResults: [Product] = []
    @Published var isLoading = false

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
}
