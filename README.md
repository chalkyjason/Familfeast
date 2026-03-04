# FamilyFeast

**A Consensus-Driven Meal Planning Platform for iOS**

FamilyFeast solves the age-old question "What's for dinner?" by transforming meal planning from a one-person chore into a collaborative family activity. Using democratic voting, AI-powered suggestions, and seamless CloudKit synchronization, FamilyFeast makes meal planning fun, fair, and efficient.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

### Core Functionality

- **Family Collaboration**
  - Multi-user support via CloudKit
  - Secure family group invitations
  - Real-time synchronization across all devices

- **Democratic Voting System**
  - Tinder-style swipe interface (Like/Dislike/OK)
  - Borda Count consensus algorithm
  - Prevents polarizing choices that leave family members unhappy

- **AI-Powered Features**
  - Recipe suggestions from text descriptions or available ingredients
  - Import recipes from any URL via AI parsing
  - Smart ingredient parsing from natural language

- **Recipe Scaling & Cooking Mode**
  - Scale ingredients up or down by adjusting servings
  - Step-by-step cooking mode with built-in countdown timer
  - Nutrition info display (calories, protein, carbs, fat, fiber, sodium)

- **Smart Shopping Lists**
  - Auto-generated from meal plans
  - Organized by grocery store aisle/category
  - Budget tracking and cost estimation
  - Collaborative checking with haptic feedback

- **Meal Scheduling**
  - Weekly calendar with meal session management
  - Considers prep time and family schedule
  - Dietary conflict warnings based on family member profiles

- **Dietary Preference Profiles**
  - Per-member dietary restrictions (Vegetarian, Vegan, Gluten-Free, Keto, etc.)
  - Allergen tracking (Peanuts, Tree Nuts, Shellfish, Dairy, etc.)
  - Cuisine preferences (Italian, Mexican, Thai, Indian, etc.)
  - Automatic conflict warnings during meal planning

- **Budget Management**
  - Cost estimation per recipe and per meal plan
  - Track actual spending vs. estimates
  - Budget alerts when approaching limits

## Architecture

### Technical Stack

- **Frontend**: SwiftUI with iOS 17+ features
- **Data Persistence**: SwiftData (successor to Core Data)
- **Synchronization**: CloudKit with shared database containers
- **AI Integration**: OpenAI GPT-4o-mini for cost-effective intelligence
- **Recipe Data**: Spoonacular API for ingredient pricing and nutrition
- **Project Generation**: XcodeGen from `project.yml`
- **Design Pattern**: MVVM with service-oriented architecture

### Project Structure

```
FamilyFeast/
├── Sources/
│   ├── App/
│   │   └── FamilyFeastApp.swift          # Main app entry point
│   ├── Models/                            # SwiftData models
│   │   ├── FamilyGroup.swift             # Family container + FamilyMember
│   │   ├── Recipe.swift                  # Recipe entity + NutritionInfo
│   │   ├── Ingredient.swift              # Ingredient with parsing
│   │   ├── Vote.swift                    # Vote with scoring
│   │   ├── MealSession.swift             # Voting session + ScheduledMeal
│   │   └── ShoppingList.swift            # Shopping list entities
│   ├── Views/
│   │   ├── ContentView.swift             # Root tab view
│   │   ├── Onboarding/
│   │   │   └── OnboardingView.swift      # First-time setup wizard
│   │   ├── Dashboard/
│   │   │   └── DashboardView.swift       # Home screen with quick actions
│   │   ├── Recipe/
│   │   │   ├── RecipeListView.swift      # Recipe list, detail, and add views
│   │   │   ├── CookingModeView.swift     # Step-by-step cooking with timer
│   │   │   ├── RecipeURLImportView.swift # Import recipes from URLs via AI
│   │   │   └── AISuggestionsView.swift   # AI-powered recipe suggestions
│   │   ├── Voting/
│   │   │   ├── VotingSessionView.swift   # Session management
│   │   │   └── VotingCardView.swift      # Swipe card UI
│   │   ├── MealPlanning/
│   │   │   └── MealPlanningView.swift    # Calendar and planning
│   │   ├── Shopping/
│   │   │   └── ShoppingListView.swift    # Shopping list UI
│   │   └── Family/
│   │       ├── FamilySettingsView.swift      # Family group settings
│   │       ├── DietaryRestrictionsView.swift # Per-member dietary/allergen config
│   │       └── CuisinePreferencesView.swift  # Per-member cuisine preferences
│   ├── Services/
│   │   ├── CloudKitService.swift         # CloudKit operations
│   │   ├── AIService.swift               # OpenAI integration
│   │   └── SpoonacularService.swift      # Recipe API
│   └── Utilities/
│       └── VotingAlgorithm.swift         # Consensus algorithms
├── FamilyFeast.entitlements              # CloudKit entitlements
├── project.yml                           # XcodeGen project spec
└── Tests/
    └── VotingAlgorithmTests.swift        # Unit tests
```

## Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+ SDK**
- **Apple Developer Account** (for CloudKit on device)
- **OpenAI API Key** (optional, for AI features)
- **Spoonacular API Key** (optional, for pricing data)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/chalkyjason/Familfeast.git
   cd Familfeast
   ```

2. **Open in Xcode**
   ```bash
   open FamilyFeast.xcodeproj
   ```
   The Xcode project is included in the repo. Just open it and build.

   > **Regenerating the project** (optional): If you modify `project.yml`, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate`.

3. **Configure Signing**
   - In Xcode, select the FamilyFeast target
   - Go to "Signing & Capabilities"
   - Select your development team
   - CloudKit entitlements are already configured in `FamilyFeast.entitlements`

4. **Set up API Keys** (optional)

   **Option 1: Xcode Scheme Environment Variables (Recommended)**
   - Edit Scheme > Run > Arguments > Environment Variables
   - Add `OPENAI_API_KEY` and `SPOONACULAR_API_KEY`

   **Option 2: Create Secrets File**
   Create `Sources/Utilities/Secrets.swift`:
   ```swift
   enum Secrets {
       static let openAIKey = "your-openai-api-key"
       static let spoonacularKey = "your-spoonacular-api-key"
   }
   ```
   This file is already in `.gitignore`.

5. **Build and Run**
   - Select a simulator or device
   - Press Cmd+R to build and run

### First-Time Setup

1. Launch the app and follow the onboarding wizard
2. Name your family group
3. Add recipes (manually, via AI suggestions, or import from URL)
4. Create a voting session and invite family members to vote
5. Generate shopping lists from finalized meal plans

## Running on Simulator vs Device

- **Simulator**: Works fully for local features. CloudKit sync is unavailable (the app gracefully falls back to local-only mode).
- **Device**: Full CloudKit sync requires an Apple Developer account and iCloud sign-in.

## Testing

### Run Unit Tests
```bash
# Via Xcode
Cmd+U

# Via command line (requires xcodebuild)
xcodebuild test -project FamilyFeast.xcodeproj -scheme FamilyFeast -destination 'platform=iOS Simulator,name=iPhone 16'
```

### Test Coverage
- Voting algorithm (Borda Count)
- Consensus metrics calculation
- Schulze method ranking
- Budget constraint filtering
- Performance tests for large datasets

## Voting Algorithm

FamilyFeast uses a **Modified Borda Count** system to achieve consensus:

### Vote Values
- **Super Like**: +2 points
- **Like**: +1 point
- **OK**: 0 points
- **Dislike**: -100 points (soft veto)
- **Veto**: Disqualified (hard constraint, e.g., allergy)

### Selection Process
1. **Nomination**: Head of Household or AI selects candidate recipes
2. **Deliberation**: Family members vote asynchronously via swipe UI
3. **Resolution**: Algorithm calculates scores and selects top N recipes
4. **Ratification**: HoH schedules winning recipes to specific days

## Privacy & Security

- **End-to-End Encryption**: CloudKit uses Apple's encryption for all synced data
- **No Account Creation**: Uses existing iCloud credentials
- **Local-First**: All data stored locally with optional cloud sync
- **No Third-Party Tracking**: Zero analytics or tracking SDKs

## Roadmap

### Phase 1: Foundation
- [x] SwiftData models
- [x] CloudKit integration
- [x] Voting algorithm
- [x] Basic UI components
- [x] Voting UI (Tinder-style swipe)
- [x] End-to-end meal session flow
- [x] Shopping list generation from meal plans

### Phase 2: Core Features
- [x] Complete recipe entry forms
- [x] AI recipe suggestions and generation
- [x] Recipe import from URLs
- [x] Recipe scaling (adjust servings)
- [x] Nutrition information display
- [x] Step-by-step cooking mode with timer
- [x] Dietary preference profiles (restrictions, allergens, cuisine prefs)
- [x] Dietary conflict warnings in meal planning
- [ ] Drag-and-drop calendar
- [ ] Budget tracking dashboard

### Phase 3: Polish
- [ ] Recipe image upload and storage
- [ ] Meal history and favorites
- [ ] Push notifications for voting reminders

### Phase 4: Advanced
- [ ] Pantry inventory tracking
- [ ] Expiration date alerts
- [ ] Grocery store API integration (Kroger, Instacart)
- [ ] Meal prep planning
- [ ] Leftovers tracking

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- **Voting Theory**: Inspired by Condorcet methods and social choice theory
- **Design**: Tinder's swipe interface for intuitive voting
- **APIs**: OpenAI for AI capabilities, Spoonacular for recipe data
- **Apple**: SwiftUI, SwiftData, and CloudKit frameworks

## Contact

- **GitHub**: [@chalkyjason](https://github.com/chalkyjason)
