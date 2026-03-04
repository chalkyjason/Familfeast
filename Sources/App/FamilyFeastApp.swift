import SwiftUI
import SwiftData

@main
struct FamilyFeastApp: App {

    // MARK: - Properties

    /// SwiftData model container with CloudKit sync
    let modelContainer: ModelContainer

    /// Services
    @State private var aiService: AIService?
    @State private var cloudKitService: CloudKitService

    // MARK: - Initialization

    init() {
        // Initialize CloudKit service
        cloudKitService = CloudKitService()

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

            print("✅ SwiftData container initialized successfully")

        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }

        // Configure AI service
        #if DEBUG
        let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        #else
        let openAIKey = "" // Load from keychain or secure storage
        #endif

        if !openAIKey.isEmpty {
            aiService = AIService(apiKey: openAIKey)
            print("✅ AI Service configured")
        } else {
            print("⚠️ OpenAI API key not found")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.cloudKitService, cloudKitService)
                .environment(\.aiService, aiService)
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

extension EnvironmentValues {
    var cloudKitService: CloudKitService {
        get { self[CloudKitServiceKey.self] }
        set { self[CloudKitServiceKey.self] = newValue }
    }

    var aiService: AIService? {
        get { self[AIServiceKey.self] }
        set { self[AIServiceKey.self] = newValue }
    }
}
