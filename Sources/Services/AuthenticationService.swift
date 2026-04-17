import Foundation
import AuthenticationServices

@Observable
final class AuthenticationService {

    // MARK: - Properties

    private(set) var isSignedIn: Bool = false
    private(set) var userID: String?
    private(set) var displayName: String?
    private(set) var email: String?

    private let userIDKey = "appleUserID"
    private let displayNameKey = "appleDisplayName"
    private let emailKey = "appleEmail"

    // MARK: - Initialization

    init() {
        loadStoredCredentials()
    }

    // MARK: - Sign In

    func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                return
            }

            let userID = credential.user

            // Apple only provides name/email on the FIRST sign-in.
            // Store them immediately; on subsequent sign-ins these will be nil.
            var name = displayName
            if let fullName = credential.fullName {
                let components = [fullName.givenName, fullName.familyName].compactMap { $0 }
                if !components.isEmpty {
                    name = components.joined(separator: " ")
                }
            }

            let email = credential.email ?? self.email

            save(userID: userID, displayName: name, email: email)

        case .failure(let error):
            print("Sign in with Apple failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Credential Check

    func checkCredentialState() async {
        guard let userID = UserDefaults.standard.string(forKey: userIDKey) else {
            await MainActor.run { isSignedIn = false }
            return
        }

        do {
            let state = try await ASAuthorizationAppleIDProvider().credentialState(forUserID: userID)
            await MainActor.run {
                switch state {
                case .authorized:
                    isSignedIn = true
                    self.userID = userID
                    self.displayName = UserDefaults.standard.string(forKey: displayNameKey)
                    self.email = UserDefaults.standard.string(forKey: emailKey)
                case .revoked, .notFound:
                    signOut()
                default:
                    break
                }
            }
        } catch {
            print("Credential state check failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Sign Out

    func signOut() {
        UserDefaults.standard.removeObject(forKey: userIDKey)
        UserDefaults.standard.removeObject(forKey: displayNameKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
        isSignedIn = false
        userID = nil
        displayName = nil
        email = nil
    }

    // MARK: - Private

    private func save(userID: String, displayName: String?, email: String?) {
        UserDefaults.standard.set(userID, forKey: userIDKey)
        if let displayName { UserDefaults.standard.set(displayName, forKey: displayNameKey) }
        if let email { UserDefaults.standard.set(email, forKey: emailKey) }

        self.userID = userID
        self.displayName = displayName
        self.email = email
        self.isSignedIn = true
    }

    private func loadStoredCredentials() {
        if let storedID = UserDefaults.standard.string(forKey: userIDKey) {
            userID = storedID
            displayName = UserDefaults.standard.string(forKey: displayNameKey)
            email = UserDefaults.standard.string(forKey: emailKey)
            isSignedIn = true
        }
    }
}
