import SwiftUI

struct AuthView: View {
    @EnvironmentObject var auth: AuthService
    @State private var mode: Mode = .signIn
    @State private var email    = ""
    @State private var password = ""
    @FocusState private var focused: Field?

    enum Mode { case signIn, signUp }
    enum Field { case email, password }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // Logo
                    VStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#34c759"), Color(hex: "#30d158")],
                                    startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 72, height: 72)
                            Text("🥦").font(.system(size: 38))
                        }
                        Text("Gist")
                            .font(.system(size: 32, weight: .bold))
                        Text("Grocery Intelligence, Simplified")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)

                    // Mode toggle
                    Picker("Mode", selection: $mode) {
                        Text("Sign In").tag(Mode.signIn)
                        Text("Create Account").tag(Mode.signUp)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 24)

                    // Fields
                    VStack(spacing: 12) {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .focused($focused, equals: .email)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)

                        SecureField("Password (min 6 characters)", text: $password)
                            .focused($focused, equals: .password)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 24)

                    // Error
                    if let msg = auth.errorMessage {
                        Text(msg)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    // Action button
                    Button {
                        focused = nil
                        Task {
                            if mode == .signIn {
                                await auth.signIn(email: email, password: password)
                            } else {
                                await auth.signUp(email: email, password: password)
                            }
                        }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text(mode == .signIn ? "Sign In" : "Create Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            email.isEmpty || password.count < 6
                                ? Color(.systemGray3)
                                : Color(hex: "#34c759")
                        )
                        .cornerRadius(14)
                    }
                    .disabled(email.isEmpty || password.count < 6 || auth.isLoading)
                    .padding(.horizontal, 24)

                    Text("Your data is stored securely and synced across devices.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer(minLength: 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
