import SwiftUI

struct GistScoreView: View {
    let score: Int?

    private var displayScore: Int { score ?? 0 }
    private var color: Color {
        guard let s = score else { return Color(hex: "#888888") }
        return Color(hex: ScoringService.shared.gistScoreColor(for: s))
    }
    private var label: String {
        guard score != nil else { return "N/A" }
        return "\(displayScore)"
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 4)

            Circle()
                .trim(from: 0, to: score != nil ? CGFloat(displayScore) / 100.0 : 0)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.6), value: score)

            VStack(spacing: 0) {
                Text(label)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(color)
                if score != nil {
                    Text("Gist")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 44, height: 44)
    }
}

struct GistScoreDetailView: View {
    let score: Int?
    let additives: [AdditiveRisk]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                GistScoreView(score: score)
                    .frame(width: 60, height: 60)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gist Score")
                        .font(.headline)
                    if let s = score {
                        Text(scoreLabel(s))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No data available")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }

            let highRisk = ScoringService.shared.highRiskAdditives(from: additives)
            if !highRisk.isEmpty {
                Divider()
                Text("High-Risk Additives")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(hex: "#e63c2f"))
                ForEach(highRisk) { additive in
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(additive.riskLevel >= 3 ? Color(hex: "#e63c2f") : Color(hex: "#f5841f"))
                            .font(.system(size: 12))
                        Text(additive.name)
                            .font(.system(size: 13, weight: .medium))
                        Spacer()
                        Text(riskLabel(additive.riskLevel))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func scoreLabel(_ s: Int) -> String {
        switch s {
        case 75...100: return "Excellent health profile"
        case 50..<75: return "Good health profile"
        case 30..<50: return "Moderate health profile"
        case 15..<30: return "Poor health profile"
        default: return "Very poor health profile"
        }
    }

    private func riskLabel(_ level: Int) -> String {
        switch level {
        case 0: return "Low risk"
        case 1: return "Moderate"
        case 2: return "High risk"
        case 3: return "Very high risk"
        default: return ""
        }
    }
}
