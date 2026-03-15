import Foundation

/// Replace these two values with your Supabase project credentials.
/// Dashboard → Settings → API
enum SupabaseConfig {
    static let url     = "https://YOUR_PROJECT_REF.supabase.co"
    static let anonKey = "YOUR_ANON_KEY"

    static var baseHeaders: [String: String] {
        ["apikey": anonKey, "Content-Type": "application/json"]
    }

    static func authHeaders(token: String) -> [String: String] {
        [
            "apikey":        anonKey,
            "Authorization": "Bearer \(token)",
            "Content-Type":  "application/json",
            "Accept":        "application/json",
        ]
    }
}
