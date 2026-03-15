import SwiftUI

struct NutriScoreBadge: View {
    let grade: String?

    private var fullLabel: String {
        switch grade?.lowercased() {
        case "a": return "Nutri-Score A, Excellent"
        case "b": return "Nutri-Score B, Good"
        case "c": return "Nutri-Score C, Fair"
        case "d": return "Nutri-Score D, Poor"
        case "e": return "Nutri-Score E, Bad"
        default:  return "Nutri-Score unknown"
        }
    }

    var body: some View {
        let displayText = grade.map { $0.uppercased() } ?? "?"
        Text(displayText)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 22, height: 22)
            .background(Color(hex: ScoringService.shared.nutriscoreColor(for: grade)))
            .cornerRadius(4)
            .accessibilityLabel(fullLabel)
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

    private var fullLabel: String {
        switch group {
        case 1: return "NOVA Group 1, Unprocessed food"
        case 2: return "NOVA Group 2, Processed culinary ingredient"
        case 3: return "NOVA Group 3, Processed food"
        case 4: return "NOVA Group 4, Ultra-processed food"
        default: return "NOVA Group unknown"
        }
    }

    var body: some View {
        let displayText = group.map { "N\($0)" } ?? "N?"
        Text(displayText)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 24, height: 22)
            .background(color)
            .cornerRadius(4)
            .accessibilityLabel(fullLabel)
    }
}

struct AdditiveWarningBadge: View {
    let count: Int

    var body: some View {
        if count > 0 {
            HStack(spacing: 2) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 9))
                    .accessibilityHidden(true)
                Text("\(count)")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .frame(height: 22)
            .background(Color(hex: "#e63c2f"))
            .cornerRadius(4)
            .accessibilityLabel("\(count) high-risk additive\(count == 1 ? "" : "s") detected")
        }
    }
}
