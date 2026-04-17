import SwiftUI
import AuthenticationServices

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
                .foregroundStyle(.blue.gradient)

            Text("FamilyFeast")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Collaborative meal planning\nfor the whole family")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            // Feature highlights
            VStack(alignment: .leading, spacing: 14) {
                HighlightRow(icon: "person.3.fill", text: "Vote on meals as a family")
                HighlightRow(icon: "cart.fill", text: "Smart shopping lists")
                HighlightRow(icon: "icloud.fill", text: "Syncs across all your devices")
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
                // User cancelled, don't show error
                return
            }
            errorMessage = "Sign in failed. Please try again."
            authService.handleSignInResult(result)
        }
    }
}

// MARK: - Supporting Views

private struct HighlightRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 30)
            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    SignInView()
}
