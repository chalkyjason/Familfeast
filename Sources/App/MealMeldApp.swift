import SwiftUI
import SwiftData
import OSLog

@main
struct MealMeldApp: App {

    // MARK: - Properties

    /// SwiftData model container with CloudKit sync
    let modelContainer: ModelContainer

    /// Services
    @State private var aiService: AIService?
    @State private var cloudKitService: CloudKitService
    @State private var authService: AuthenticationService

    // MARK: - Initialization

    init() {
        Logger.app.info("Application starting up...")
        
        // Initialize services
        let ckService = CloudKitService()
        cloudKitService = ckService
        authService = AuthenticationService()
        
        // Activate CloudKit with configured container
        Task {
            await ckService.activateCloudKit()
        }
        
        // Initialize AI service
        aiService = AIService()
        
        Logger.app.info("Services initialized.")

        // Configure SwiftData model container
        do {
            // Define the schema
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

            // Configure model container with CloudKit sync
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .none
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            Logger.database.info("SwiftData container initialized successfully")

        } catch {
            Logger.database.fault("Failed to initialize SwiftData container: \(error.localizedDescription)")
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.cloudKitService, cloudKitService)
                .environment(\.aiService, aiService)
                .environment(\.authService, authService)
        }
    }

}

// MARK: - Environment Keys

/// Environment key for CloudKit service
private struct CloudKitServiceKey: EnvironmentKey {
    static let defaultValue: CloudKitService = CloudKitService()
}

/// Environment key for AI service
private struct AIServiceKey: EnvironmentKey {
    static let defaultValue: AIService? = nil
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

    var aiService: AIService? {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }

    var authService: AuthenticationService {
        get { self[AuthenticationServiceKey.self] }
        set { self[AuthenticationServiceKey.self] = newValue }
    }
}
