import SwiftUI

struct NutriScoreBadge: View {
    let grade: String?

    var body: some View {
        if let g = grade?.uppercased(), !g.isEmpty {
            Text(g)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color(hex: ScoringService.shared.nutriscoreColor(for: grade)))
                .cornerRadius(4)
        } else {
            Text("?")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color(hex: "#888888"))
                .cornerRadius(4)
        }
    }
}

struct NovaBadge: View {
    let group: Int?

    private var color: Color {
        switch group {
        case 1: return Color(hex: "#1a9e3f")
        case 2: return Color(hex: "#7ac94b")
        case 3: return Color(hex: "#f5841f")
        case 4: return Color(hex: "#e63c2f")
        default: return Color(hex: "#888888")
        }
    }

    var body: some View {
        if let g = group {
            Text("N\(g)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 22)
                .background(color)
                .cornerRadius(4)
        } else {
            Text("N?")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 22)
                .background(Color(hex: "#888888"))
                .cornerRadius(4)
        }
    }
}

struct AdditiveWarningBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(Color(hex: "#e63c2f"))
            .cornerRadius(4)
        }
    }
}
