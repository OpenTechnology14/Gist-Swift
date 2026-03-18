import Foundation

// MARK: - TursoAuthService
// Drop-in replacement for AuthService.swift when using Turso instead of Supabase.
// Swap by replacing `AuthService.shared` references with `TursoAuthService.shared`.

@MainActor
final class TursoAuthService: ObservableObject {
    static let shared = TursoAuthService()

    @Published var isSignedIn  = false
    @Published var profile: UserProfile?
    @Published var isLoading   = false
    @Published var errorMessage: String?

    private var accessToken: String?

    private let session = URLSession.shared
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // Keychain keys (same as AuthService — seamless migration)
    private let kToken  = "gist_token"
    private let kUserId = "gist_user_id"
    private let kEmail  = "gist_email"

    private init() {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let token = KeychainHelper.load(key: kToken) {
            accessToken = token
            Task { await loadProfile() }
        }
    }

    // MARK: - Public API

    var token: String? { accessToken }

    func signUp(email: String, password: String) async {
        await authRequest(action: "signup", email: email, password: password)
    }

    func signIn(email: String, password: String) async {
        await authRequest(action: "signin", email: email, password: password)
    }

    func signOut() {
        [kToken, kUserId, kEmail].forEach { KeychainHelper.delete(key: $0) }
        accessToken = nil
        profile     = nil
        isSignedIn  = false
    }

    // MARK: - Admin

    func fetchAllUsers() async -> [UserProfile] {
        guard let token, profile?.isAdmin == true,
              let url = URL(string: "\(TursoConfig.apiBase)/api/auth?action=users") else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([UserProfile].self, from: data)) ?? []
        } catch { return [] }
    }

    func updateUserLimits(userId: String, maxLists: Int, maxItems: Int) async -> Bool {
        guard let token, profile?.isAdmin == true,
              let url = URL(string: "\(TursoConfig.apiBase)/api/auth?action=limits") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "userId": userId, "maxLists": maxLists, "maxItems": maxItems,
        ])
        do {
            let (_, resp) = try await session.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 204
        } catch { return false }
    }

    // MARK: - Internals

    private func authRequest(action: String, email: String, password: String) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(TursoConfig.apiBase)/api/auth?action=\(action)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = TursoConfig.jsonHeaders()
        req.httpBody = try? encoder.encode(["email": email, "password": password])

        do {
            let (data, _) = try await session.data(for: req)
            let resp = try decoder.decode(TursoAuthResponse.self, from: data)
            if let errMsg = resp.error {
                errorMessage = errMsg; return
            }
            guard let token = resp.accessToken, let user = resp.user else { return }
            accessToken = token
            KeychainHelper.save(key: kToken,  value: token)
            KeychainHelper.save(key: kUserId, value: user.id)
            KeychainHelper.save(key: kEmail,  value: user.email)
            profile    = user
            isSignedIn = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfile() async {
        guard let token,
              let url = URL(string: "\(TursoConfig.apiBase)/api/auth?action=profile") else { return }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = TursoConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            if let p = try? decoder.decode(UserProfile.self, from: data) {
                profile    = p
                isSignedIn = true
            } else {
                // Token expired or invalid — sign out cleanly
                signOut()
            }
        } catch {
            // Offline — stay signed in with cached identity
            if let userId = KeychainHelper.load(key: kUserId),
               let email  = KeychainHelper.load(key: kEmail) {
                profile    = UserProfile(id: userId, email: email, role: "user", maxLists: 4, maxItems: 50)
                isSignedIn = true
            }
        }
    }
}

// MARK: - Response types

private struct TursoAuthResponse: Decodable {
    let accessToken: String?
    let user:        UserProfile?
    let error:       String?
}
