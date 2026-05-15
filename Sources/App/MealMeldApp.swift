import SwiftUI
import SwiftData
import OSLog

@main
struct MealMeldApp: App {

    // MARK: - Properties

    /// SwiftData model container (local-only)
    let modelContainer: ModelContainer?
    let modelContainerError: Error?

    /// Services
    @State private var cloudKitService: CloudKitService
    @State private var authService: AuthenticationService

    // MARK: - Initialization

    init() {
        Logger.app.info("Application starting up...")

        let ckService = CloudKitService()
        cloudKitService = ckService
        authService = AuthenticationService()

        Task {
            await ckService.activateCloudKit()
        }

        Logger.app.info("Services initialized.")

        let schema = Schema([
            FamilyGroup.self,
            FamilyMember.self,
            Recipe.self,
            Ingredient.self,
            Vote.self,
            MealSession.self,
            ScheduledMeal.self,
            ShoppingList.self,
            ShoppingListItem.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .none
        )

        do {
            modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            modelContainerError = nil
            Logger.database.info("SwiftData container initialized successfully")
        } catch {
            modelContainer = nil
            modelContainerError = error
            Logger.database.fault("Failed to initialize SwiftData container: \(error.localizedDescription)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            if let container = modelContainer {
                ContentView()
                    .modelContainer(container)
                    .environment(\.cloudKitService, cloudKitService)
                    .environment(\.authService, authService)
            } else {
                StorageUnavailableView(error: modelContainerError)
            }
        }
    }

}

// MARK: - Environment Keys

/// Environment key for CloudKit service
private struct CloudKitServiceKey: EnvironmentKey {
    static let defaultValue: CloudKitService = CloudKitService()
}

/// Environment key for Authentication service
private struct AuthenticationServiceKey: EnvironmentKey {
    static let defaultValue: AuthenticationService = AuthenticationService()
}

extension EnvironmentValues {
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }

    var authService: AuthenticationService {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}

private struct StorageUnavailableView: View {
    let error: Error?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "externaldrive.badge.exclamationmark")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("MealMeld can't open its local database")
                .font(.title2)
                .multilineTextAlignment(.center)
            Text("Reinstalling the app usually resolves this. Your data is stored only on this device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
    }
}
