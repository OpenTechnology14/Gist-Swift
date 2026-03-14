import SwiftUI

struct SearchBar: View {
    @Binding var text: String
    var placeholder: String = "Search products..."
    var onScanTap: (() -> Void)?
    var suggestion: String? = nil
    var onSuggestionTap: (() -> Void)? = nil

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .padding(.leading, 8)

                    TextField(placeholder, text: $text)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($isFocused)

                    if !text.isEmpty {
                        Button {
                            text = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .padding(.trailing, 4)
                    }
                }
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(12)

                if let onScanTap = onScanTap {
                    Button(action: onScanTap) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 22))
                            .foregroundColor(Color(hex: "#7ac94b"))
                            .frame(width: 44, height: 44)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            if isFocused && text.isEmpty, let suggestion = suggestion {
                Button(action: { onSuggestionTap?() }) {
                    HStack(spacing: 10) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 14))
                            .foregroundColor(Color(.systemGray3))
                        Text(suggestion)
                            .font(.system(size: 15))
                            .foregroundColor(Color(.systemGray3))
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color(.systemBackground))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
