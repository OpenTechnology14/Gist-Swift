import SwiftUI

struct AdminView: View {
    @EnvironmentObject var auth: AuthService
    @State private var users:     [UserProfile] = []
    @State private var isLoading  = false
    @State private var editTarget: UserProfile?

    var body: some View {
        NavigationStack {
            Group {
                if isLoading && users.isEmpty {
                    ProgressView("Loading users…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(users) { user in
                        UserRow(user: user) {
                            editTarget = user
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Admin Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") { Task { await load() } }
                        .font(.system(size: 14))
                }
            }
            .sheet(item: $editTarget) { user in
                EditLimitsSheet(user: user) { maxLists, maxItems in
                    Task {
                        let ok = await auth.updateUserLimits(
                            userId: user.id, maxLists: maxLists, maxItems: maxItems
                        )
                        if ok { await load() }
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        users = await auth.fetchAllUsers()
        isLoading = false
    }
}

// MARK: - User Row

private struct UserRow: View {
    let user: UserProfile
    var onEdit: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(user.email)
                        .font(.system(size: 14, weight: .medium))
                    if user.isAdmin {
                        Text("admin")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#34c759"))
                            .cornerRadius(4)
                    }
                }
                Text("Lists: \(user.maxLists)  ·  Items: \(user.maxItems)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button("Edit") { onEdit() }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(hex: "#34c759"))
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Limits Sheet

private struct EditLimitsSheet: View {
    @Environment(\.dismiss) private var dismiss
    let user: UserProfile
    var onSave: (Int, Int) -> Void

    @State private var maxLists: Int
    @State private var maxItems: Int

    init(user: UserProfile, onSave: @escaping (Int, Int) -> Void) {
        self.user    = user
        self.onSave  = onSave
        _maxLists    = State(initialValue: user.maxLists)
        _maxItems    = State(initialValue: user.maxItems)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("User") {
                    LabeledContent("Email", value: user.email)
                    LabeledContent("Role",  value: user.role)
                }
                Section("Limits") {
                    Stepper("Max Lists: \(maxLists)", value: $maxLists, in: 1...50)
                    Stepper("Max Items: \(maxItems)", value: $maxItems, in: 1...500)
                }
            }
            .navigationTitle("Edit Limits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(maxLists, maxItems)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
