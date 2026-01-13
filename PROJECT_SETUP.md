# FamilyFeast - Project Setup Guide

## Overview
FamilyFeast is a consensus-driven meal planning iOS application built with SwiftUI, SwiftData, and CloudKit.

## Setting up in Xcode

### Option 1: Create New Xcode Project (Recommended for iOS App)
1. Open Xcode
2. Create a new iOS App project
3. Set:
   - Product Name: `FamilyFeast`
   - Interface: `SwiftUI`
   - Storage: `SwiftData`
   - Language: `Swift`
   - Minimum iOS: `17.0`
4. Copy all files from the `Sources/` directory into your Xcode project
5. Enable CloudKit capability in Signing & Capabilities
6. Add a CloudKit Container: `iCloud.com.yourteam.FamilyFeast`

### Option 2: Open as Swift Package
1. Open `Package.swift` in Xcode
2. This provides the source code structure
3. Create a separate iOS App target to run the application

## Required Capabilities
- **CloudKit**: For multi-user synchronization
- **iCloud**: For CloudKit containers
- **Background Modes**: For CloudKit notifications

## API Keys Required
Create a `Secrets.swift` file with:
```swift
enum Secrets {
    static let openAIKey = "your-openai-api-key"
    static let spoonacularKey = "your-spoonacular-api-key"
}
```

## CloudKit Setup
1. In Xcode, enable CloudKit capability
2. Create a new container or use automatic
3. In CloudKit Dashboard:
   - Create custom record types matching SwiftData models
   - Enable sharing permissions
   - Configure security roles

## Architecture Overview
- **SwiftUI**: All UI components
- **SwiftData**: Local persistence and CloudKit sync
- **CloudKit**: Multi-user sharing and real-time sync
- **MVVM**: Architecture pattern with ViewModels
- **OpenAI API**: Recipe suggestions and ingredient parsing
- **Spoonacular API**: Recipe data and price estimation

## Project Structure
```
FamilyFeast/
├── Sources/
│   ├── App/
│   │   └── FamilyFeastApp.swift
│   ├── Models/
│   │   ├── Recipe.swift
│   │   ├── Ingredient.swift
│   │   ├── FamilyGroup.swift
│   │   ├── MealSession.swift
│   │   └── Vote.swift
│   ├── Views/
│   │   ├── ContentView.swift
│   │   ├── Recipe/
│   │   ├── Voting/
│   │   ├── Shopping/
│   │   └── Schedule/
│   ├── ViewModels/
│   ├── Services/
│   │   ├── CloudKitService.swift
│   │   ├── AIService.swift
│   │   └── SpoonacularService.swift
│   └── Utilities/
│       ├── VotingAlgorithm.swift
│       └── IngredientParser.swift
└── Tests/
    └── VotingAlgorithmTests.swift
```

## Development Phases
1. **Phase 1**: Local app with SwiftData (Weeks 1-4)
2. **Phase 2**: CloudKit multi-user sync (Weeks 5-8)
3. **Phase 3**: AI integration and voting (Weeks 9-12)

## Testing
Run tests with: `⌘U` in Xcode or `swift test` in terminal
