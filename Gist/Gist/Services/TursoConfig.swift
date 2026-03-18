import Foundation

/// Configuration for the Turso auth + data API (your Vercel deployment).
///
/// Replace `apiBase` with your Vercel project URL before building.
/// Dashboard → Settings → Domains, or copy the .vercel.app URL from the
/// deployment summary.
///
/// The app never talks to Turso directly — all requests go through the
/// Vercel serverless functions in /api, which hold the Turso credentials
/// server-side.
enum TursoConfig {
    /// Base URL of your Vercel deployment — no trailing slash.
    static let apiBase = "https://YOUR_VERCEL_URL"

    static func jsonHeaders() -> [String: String] {
        ["Content-Type": "application/json", "Accept": "application/json"]
    }

    static func authHeaders(token: String) -> [String: String] {
        [
            "Authorization": "Bearer \(token)",
            "Content-Type":  "application/json",
            "Accept":        "application/json",
        ]
    }
}
