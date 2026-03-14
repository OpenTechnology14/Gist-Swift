import Foundation

class ScoringService {
    static let shared = ScoringService()

    private let additiveRiskMap: [String: Int] = {
        var map: [String: Int] = [:]
        // Risk 0 (low)
        for code in ["E200", "E202", "E203", "E300", "E301", "E302", "E304",
                     "E306", "E307", "E308", "E309", "E322", "E331", "E332",
                     "E333", "E334", "E410", "E412", "E414", "E415", "E440"] {
            map[code.lowercased()] = 0
        }
        // Risk 1 (moderate)
        for code in ["E218", "E219", "E220", "E221", "E222", "E223", "E224",
                     "E104", "E120", "E127", "E132", "E133", "E171",
                     "E311", "E312", "E407", "E408", "E416", "E425",
                     "E472e", "E476", "E479b", "E620", "E622", "E623",
                     "E624", "E625", "E626", "E627", "E628", "E629",
                     "E630", "E631", "E632", "E633", "E634", "E635"] {
            map[code.lowercased()] = 1
        }
        // Risk 2 (high)
        for code in ["E210", "E211", "E212", "E213", "E214", "E215",
                     "E230", "E231", "E232",
                     "E102", "E110", "E122", "E124", "E128", "E129",
                     "E131", "E142", "E150c", "E150d", "E151", "E155",
                     "E310", "E319", "E320", "E321",
                     "E951", "E952", "E954", "E621"] {
            map[code.lowercased()] = 2
        }
        // Risk 3 (very high)
        for code in ["E216", "E217", "E249", "E250", "E251", "E252", "E123"] {
            map[code.lowercased()] = 3
        }
        return map
    }()

    private let nutriscoreBase: [String: Int] = [
        "a": 90, "b": 72, "c": 54, "d": 36, "e": 18
    ]

    func parseAdditives(from tags: [String]) -> [AdditiveRisk] {
        var result: [AdditiveRisk] = []
        for tag in tags {
            // tags come as "en:e621" or "e621"
            let parts = tag.components(separatedBy: ":")
            let rawCode = parts.last ?? tag
            let normalized = rawCode.uppercased()
            let lookupKey = rawCode.lowercased()
            let risk = additiveRiskMap[lookupKey] ?? -1
            if risk >= 0 {
                result.append(AdditiveRisk(id: normalized, riskLevel: risk, name: normalized))
            }
        }
        return result
    }

    func calculateGistScore(nutriscoreGrade: String?, additives: [AdditiveRisk]) -> Int? {
        guard let grade = nutriscoreGrade?.lowercased(),
              let base = nutriscoreBase[grade] else {
            return nil
        }
        let penalty = additives
            .filter { $0.riskLevel >= 2 }
            .reduce(0) { $0 + $1.riskLevel * 3 }
        return max(0, min(100, base - penalty))
    }

    func nutriscoreColor(for grade: String?) -> String {
        switch grade?.lowercased() {
        case "a": return "#1a9e3f"
        case "b": return "#7ac94b"
        case "c": return "#f5c518"
        case "d": return "#f5841f"
        case "e": return "#e63c2f"
        default: return "#888888"
        }
    }

    func gistScoreColor(for score: Int) -> String {
        switch score {
        case 75...100: return "#1a9e3f"
        case 50..<75: return "#7ac94b"
        case 30..<50: return "#f5c518"
        case 15..<30: return "#f5841f"
        default: return "#e63c2f"
        }
    }

    func novaDescription(for group: Int?) -> String {
        switch group {
        case 1: return "Unprocessed"
        case 2: return "Processed ingredients"
        case 3: return "Processed"
        case 4: return "Ultra-processed"
        default: return "Unknown"
        }
    }

    func highRiskAdditives(from additives: [AdditiveRisk]) -> [AdditiveRisk] {
        additives.filter { $0.riskLevel >= 2 }
    }
}
