import Foundation

// MARK: - Models

struct UserProfile: Codable, Identifiable {
    let id: String
    var email: String
    var role: String       // "user" | "admin"
    var maxLists: Int
    var maxItems: Int

    enum CodingKeys: String, CodingKey {
        case id, email, role
        case maxLists = "max_lists"
        case maxItems = "max_items"
    }

    var isAdmin: Bool { role == "admin" }
}

// MARK: - AuthService

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var isSignedIn  = false
    @Published var profile: UserProfile?
    @Published var isLoading   = false
    @Published var errorMessage: String?

    private var accessToken: String?

    private let session  = URLSession.shared
    private let encoder  = JSONEncoder()
    private let decoder  = JSONDecoder()

    // Keychain keys
    private let kToken   = "gist_token"
    private let kRefresh = "gist_refresh"
    private let kUserId  = "gist_user_id"
    private let kEmail   = "gist_email"

    private init() {
        if let token  = KeychainHelper.load(key: kToken),
           let userId = KeychainHelper.load(key: kUserId),
           let email  = KeychainHelper.load(key: kEmail) {
            accessToken = token
            Task { await loadProfile(userId: userId, email: email) }
        }
    }

    // MARK: - Public API

    var token: String? { accessToken }

    func signUp(email: String, password: String) async {
        await authRequest(
            path: "/auth/v1/signup",
            body: ["email": email, "password": password]
        )
    }

    func signIn(email: String, password: String) async {
        await authRequest(
            path: "/auth/v1/token?grant_type=password",
            body: ["email": email, "password": password]
        )
    }

    func signOut() {
        [kToken, kRefresh, kUserId, kEmail].forEach { KeychainHelper.delete(key: $0) }
        accessToken = nil
        profile     = nil
        isSignedIn  = false
    }

    // MARK: - Admin

    func fetchAllUsers() async -> [UserProfile] {
        guard let token, profile?.isAdmin == true,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/profiles?select=*&order=created_at") else { return [] }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            return (try? decoder.decode([UserProfile].self, from: data)) ?? []
        } catch { return [] }
    }

    func updateUserLimits(userId: String, maxLists: Int, maxItems: Int) async -> Bool {
        guard let token, profile?.isAdmin == true,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)") else { return false }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["max_lists": maxLists, "max_items": maxItems])
        do {
            let (_, resp) = try await session.data(for: req)
            return (resp as? HTTPURLResponse)?.statusCode == 204
        } catch { return false }
    }

    // MARK: - Internals

    private func authRequest(path: String, body: [String: String]) async {
        isLoading    = true
        errorMessage = nil
        defer { isLoading = false }

        guard let url = URL(string: "\(SupabaseConfig.url)\(path)") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = SupabaseConfig.baseHeaders
        req.httpBody = try? encoder.encode(body)

        do {
            let (data, _) = try await session.data(for: req)
            let resp = try decoder.decode(AuthResponse.self, from: data)
            if let msg = resp.errorDescription ?? resp.error {
                errorMessage = msg; return
            }
            guard let token = resp.accessToken, let user = resp.user else { return }
            accessToken = token
            KeychainHelper.save(key: kToken,   value: token)
            KeychainHelper.save(key: kRefresh, value: resp.refreshToken ?? "")
            KeychainHelper.save(key: kUserId,  value: user.id)
            KeychainHelper.save(key: kEmail,   value: user.email ?? "")
            await loadProfile(userId: user.id, email: user.email ?? "")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadProfile(userId: String, email: String) async {
        guard let token,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/profiles?id=eq.\(userId)&select=*") else { return }
        var req = URLRequest(url: url)
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        do {
            let (data, _) = try await session.data(for: req)
            let profiles = try decoder.decode([UserProfile].self, from: data)
            if let p = profiles.first {
                profile    = p
                isSignedIn = true
            } else {
                await createProfile(userId: userId, email: email)
            }
        } catch {
            // Offline fallback — still mark signed in with defaults
            profile    = UserProfile(id: userId, email: email, role: "user", maxLists: 4, maxItems: 50)
            isSignedIn = true
        }
    }

    private func createProfile(userId: String, email: String) async {
        guard let token,
              let url = URL(string: "\(SupabaseConfig.url)/rest/v1/profiles") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.allHTTPHeaderFields = SupabaseConfig.authHeaders(token: token)
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "id": userId, "email": email, "role": "user", "max_lists": 4, "max_items": 50,
        ])
        do {
            let (data, _) = try await session.data(for: req)
            let profiles = try decoder.decode([UserProfile].self, from: data)
            profile    = profiles.first ?? UserProfile(id: userId, email: email, role: "user", maxLists: 4, maxItems: 50)
            isSignedIn = true
        } catch {
            profile    = UserProfile(id: userId, email: email, role: "user", maxLists: 4, maxItems: 50)
            isSignedIn = true
        }
    }
}

// MARK: - Private response types

private struct AuthResponse: Decodable {
    let accessToken:      String?
    let refreshToken:     String?
    let user:             AuthUser?
    let error:            String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case accessToken      = "access_token"
        case refreshToken     = "refresh_token"
        case user, error
        case errorDescription = "error_description"
    }
}

private struct AuthUser: Decodable {
    let id:    String
    let email: String?
}
