import SwiftUI
import SwiftData

@main
struct FamilyFeastApp: App {

    // MARK: - Properties

    /// SwiftData model container with CloudKit sync
    let modelContainer: ModelContainer

    /// Services
    @State private var aiService: AIService?
    @State private var spoonacularService: SpoonacularService?
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
                cloudKitDatabase: .automatic
            )

            modelContainer = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            print("✅ SwiftData container initialized successfully")

        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }

        // Initialize AI services (will be configured after checking for API keys)
        // These will be set up in the ContentView's onAppear
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(\.cloudKitService, cloudKitService)
                .onAppear {
                    configureServices()
                }
        }
    }

    // MARK: - Private Methods

    private func configureServices() {
        // Load API keys from configuration
        // In production, these would come from a secure configuration system

        #if DEBUG
        // Development keys (replace with your actual keys)
        let openAIKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
        let spoonacularKey = ProcessInfo.processInfo.environment["SPOONACULAR_API_KEY"] ?? ""
        #else
        // Production keys should be fetched securely
        let openAIKey = "" // Load from keychain or secure storage
        let spoonacularKey = "" // Load from keychain or secure storage
        #endif

        if !openAIKey.isEmpty {
            aiService = AIService(apiKey: openAIKey)
            print("✅ AI Service configured")
        } else {
            print("⚠️ OpenAI API key not found")
        }

        if !spoonacularKey.isEmpty {
            spoonacularService = SpoonacularService(apiKey: spoonacularKey)
            print("✅ Spoonacular Service configured")
        } else {
            print("⚠️ Spoonacular API key not found")
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

/// Environment key for Spoonacular service
private struct SpoonacularServiceKey: EnvironmentKey {
    static let defaultValue: SpoonacularService? = nil
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

    var spoonacularService: SpoonacularService? {
        get { self[SpoonacularServiceKey.self] }
        set { self[SpoonacularServiceKey.self] = newValue }
    }
}
