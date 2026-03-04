# FamilyFeast - Project Setup Guide

## Quick Start

```bash
git clone https://github.com/chalkyjason/Familfeast.git
cd Familfeast
open FamilyFeast.xcodeproj
```

Select your development team in Signing & Capabilities, then Cmd+R to build and run.

## Project Configuration

The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). The generated `.xcodeproj` is committed to the repo so you can clone and run without installing XcodeGen.

If you need to regenerate the project (e.g., after adding new files outside Xcode or modifying `project.yml`):

```bash
brew install xcodegen
xcodegen generate
```

### Key Settings (from project.yml)
- **Bundle ID**: `com.familyfeast.app`
- **Deployment Target**: iOS 17.0
- **Swift Version**: 5.9
- **Entitlements**: `FamilyFeast.entitlements` (CloudKit)

## Required Capabilities

- **iCloud / CloudKit**: For multi-user synchronization and family sharing
  - Container: `iCloud.com.familyfeast.app`
  - Entitlements are pre-configured in `FamilyFeast.entitlements`

> **Note**: CloudKit requires an Apple Developer account and iCloud sign-in on device. On the simulator, the app runs in local-only mode.

## API Keys (Optional)

The app works without API keys — AI features and price estimates are simply disabled.

### Setting Up API Keys

**Recommended: Xcode Scheme Environment Variables**

1. In Xcode: Product > Scheme > Edit Scheme
2. Select Run > Arguments > Environment Variables
3. Add:
   - `OPENAI_API_KEY` = your OpenAI key
   - `SPOONACULAR_API_KEY` = your Spoonacular key

**Alternative: Secrets File**

Create `Sources/Utilities/Secrets.swift`:
```swift
enum Secrets {
    static let openAIKey = "your-openai-api-key"
    static let spoonacularKey = "your-spoonacular-api-key"
}
```
This file is already in `.gitignore` and won't be committed.

See [API_CONFIGURATION.md](API_CONFIGURATION.md) for detailed API setup instructions.

## Architecture Overview

| Layer | Technology | Purpose |
|-------|-----------|---------|
| UI | SwiftUI | All views and navigation |
| Persistence | SwiftData | Local storage + CloudKit sync |
| Cloud | CloudKit | Multi-user sharing and real-time sync |
| AI | OpenAI GPT-4o-mini | Recipe suggestions, URL import parsing |
| Data | Spoonacular API | Ingredient pricing and nutrition |

## Project Structure

```
FamilyFeast/
├── Sources/
│   ├── App/                    # App entry point, service configuration
│   ├── Models/                 # SwiftData models (Recipe, Ingredient, FamilyGroup, etc.)
│   ├── Views/
│   │   ├── Onboarding/        # First-time setup wizard
│   │   ├── Dashboard/         # Home screen with quick actions
│   │   ├── Recipe/            # Recipe list, detail, cooking mode, AI suggestions, URL import
│   │   ├── Voting/            # Swipe-to-vote UI
│   │   ├── MealPlanning/      # Meal session management with dietary conflict warnings
│   │   ├── Shopping/          # Shopping list with category grouping
│   │   └── Family/            # Settings, dietary restrictions, cuisine preferences
│   ├── Services/              # CloudKit, AI, Spoonacular integrations
│   └── Utilities/             # Voting algorithm, helpers
├── FamilyFeast.entitlements   # CloudKit entitlements
├── project.yml                # XcodeGen spec
└── Tests/                     # Unit tests
```

## Testing

```bash
# In Xcode
Cmd+U

# Command line
xcodebuild test -project FamilyFeast.xcodeproj -scheme FamilyFeast -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Troubleshooting

**"CloudKit not available" on simulator**: Expected. The app falls back to local-only mode automatically.

**Build errors after pulling changes**: Try `xcodegen generate` to regenerate the project, then clean build (Cmd+Shift+K).

**Missing Secrets.swift**: Not needed. The app runs without API keys — AI and pricing features are disabled gracefully.
