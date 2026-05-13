import SwiftUI
import AuthenticationServices
import OSLog

struct SignInView: View {

    // MARK: - Environment

    @Environment(\.authService) private var authService
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var errorMessage: String?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App icon and branding
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 100))
                .foregroundStyle(Theme.primary.gradient)

            Text("MealMeld")
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text("Collaborative meal planning\nfor the whole family")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Feature highlights
            VStack(alignment: .leading, spacing: 18) {
                HighlightRow(icon: "hand.thumbsup.fill", text: "Vote on meals as a family")
                HighlightRow(icon: "cart.fill", text: "Smart shopping lists")
                HighlightRow(icon: "sparkles", text: "AI-powered recipe suggestions")
            }
            .padding(.horizontal, 32)

            Spacer()

            // Sign in with Apple button
            SignInWithAppleButton(.signIn, onRequest: configureRequest, onCompletion: handleResult)
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 50)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
                .frame(height: 20)
        }
    }

    // MARK: - Sign In

    private func configureRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
    }

    private func handleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success:
            errorMessage = nil
            authService.handleSignInResult(result)
        case .failure(let error):
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            Logger.auth.error("Sign in with Apple failed: \(error.localizedDescription)")
            errorMessage = "Sign in failed: \(error.localizedDescription)"
            authService.handleSignInResult(result)
        }
    }
}

// MARK: - Supporting Views

private struct HighlightRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Theme.primary)
                .frame(width: 32)
            Text(text)
                .font(.system(.body, design: .rounded))
        }
    }
}

#Preview {
    SignInView()
}
