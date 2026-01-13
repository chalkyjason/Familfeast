# FamilyFeast 🍽️

**A Consensus-Driven Meal Planning Platform for iOS**

FamilyFeast solves the age-old question "What's for dinner?" by transforming meal planning from a one-person chore into a collaborative family activity. Using democratic voting, AI-powered suggestions, and seamless CloudKit synchronization, FamilyFeast makes meal planning fun, fair, and efficient.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## 🌟 Features

### Core Functionality

- **👨‍👩‍👧‍👦 Family Collaboration**
  - Multi-user support via CloudKit
  - Secure family group invitations
  - Real-time synchronization across all devices

- **🗳️ Democratic Voting System**
  - Tinder-style swipe interface (Like/Dislike/OK)
  - Borda Count consensus algorithm
  - Prevents polarizing choices that leave family members unhappy

- **🤖 AI-Powered Features**
  - Recipe suggestions based on available ingredients
  - Intelligent ingredient parsing from natural language
  - Smart meal plan generation with dietary considerations

- **🛒 Smart Shopping Lists**
  - Auto-generated from meal plans
  - Organized by grocery store aisle
  - Budget tracking and cost estimation
  - Collaborative checking (everyone sees updates in real-time)

- **📅 Meal Scheduling**
  - Drag-and-drop weekly calendar
  - Considers prep time and family schedule
  - Prevents meal fatigue with variety optimization

- **💰 Budget Management**
  - Cost estimation per recipe and per meal plan
  - Track actual spending vs. estimates
  - Budget alerts when approaching limits

## 🏗️ Architecture

### Technical Stack

- **Frontend**: SwiftUI with iOS 17+ features
- **Data Persistence**: SwiftData (successor to Core Data)
- **Synchronization**: CloudKit with shared database containers
- **AI Integration**: OpenAI GPT-4o-mini for cost-effective intelligence
- **Recipe Data**: Spoonacular API for ingredient pricing and nutrition
- **Design Pattern**: MVVM with service-oriented architecture

### Project Structure

```
FamilyFeast/
├── Sources/
│   ├── App/
│   │   └── FamilyFeastApp.swift          # Main app entry point
│   ├── Models/                            # SwiftData models
│   │   ├── FamilyGroup.swift             # Family container
│   │   ├── FamilyMember.swift            # User representation
│   │   ├── Recipe.swift                  # Recipe entity
│   │   ├── Ingredient.swift              # Ingredient with parsing
│   │   ├── Vote.swift                    # Vote with scoring
│   │   ├── MealSession.swift             # Voting session
│   │   ├── ScheduledMeal.swift           # Calendar entry
│   │   └── ShoppingList.swift            # Shopping list entities
│   ├── Views/                             # SwiftUI views
│   │   ├── Onboarding/                   # First-time setup
│   │   ├── Dashboard/                    # Home screen
│   │   ├── Recipe/                       # Recipe management
│   │   ├── Voting/                       # Swipe voting UI
│   │   ├── MealPlanning/                 # Calendar and planning
│   │   ├── Shopping/                     # Shopping list UI
│   │   └── Family/                       # Settings and invites
│   ├── Services/                          # Business logic layer
│   │   ├── CloudKitService.swift         # CloudKit operations
│   │   ├── AIService.swift               # OpenAI integration
│   │   └── SpoonacularService.swift      # Recipe API
│   └── Utilities/
│       └── VotingAlgorithm.swift         # Consensus algorithms
└── Tests/
    └── VotingAlgorithmTests.swift        # Unit tests
```

## 🚀 Getting Started

### Prerequisites

- **Xcode 15.0+**
- **iOS 17.0+ SDK**
- **Apple Developer Account** (for CloudKit)
- **OpenAI API Key** (optional, for AI features)
- **Spoonacular API Key** (optional, for pricing data)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FamilyFeast.git
   cd FamilyFeast
   ```

2. **Open in Xcode**
   ```bash
   open Package.swift
   # OR create a new iOS App project and copy the Sources/ directory
   ```

3. **Configure CloudKit**
   - In Xcode, select your target
   - Go to "Signing & Capabilities"
   - Add "iCloud" capability
   - Enable "CloudKit"
   - Create or select a CloudKit container: `iCloud.com.yourteam.familyfeast`

4. **Set up API Keys**

   **Option 1: Environment Variables (Recommended for Development)**
   ```bash
   export OPENAI_API_KEY="sk-your-openai-key"
   export SPOONACULAR_API_KEY="your-spoonacular-key"
   ```

   **Option 2: Create Secrets File**
   Create `Sources/Utilities/Secrets.swift`:
   ```swift
   enum Secrets {
       static let openAIKey = "your-openai-api-key"
       static let spoonacularKey = "your-spoonacular-api-key"
   }
   ```
   ⚠️ **Important**: Add `Secrets.swift` to `.gitignore`

5. **Build and Run**
   - Select a simulator or device
   - Press `⌘R` to build and run
   - Sign in with an iCloud account when prompted

### First-Time Setup

1. **Create Family Group**
   - Launch the app
   - Follow the onboarding wizard
   - Name your family group

2. **Invite Family Members**
   - Go to Family tab
   - Tap "Invite Family Member"
   - Enter email or phone number
   - They'll receive an iCloud invitation

3. **Add Your First Recipe**
   - Tap "+" in Recipes tab
   - Enter manually or use AI suggestion
   - Add ingredients and instructions

4. **Start a Voting Session**
   - Go to Plan tab
   - Create a new meal session
   - Add candidate recipes
   - Family members vote via swipe interface

## 🧪 Testing

### Run Unit Tests
```bash
# Via Xcode
⌘U

# Via command line
swift test
```

### Test Coverage
- ✅ Voting algorithm (Borda Count)
- ✅ Consensus metrics calculation
- ✅ Schulze method ranking
- ✅ Budget constraint filtering
- ✅ Performance tests for large datasets

## 📊 Voting Algorithm Explained

FamilyFeast uses a **Modified Borda Count** system to achieve consensus:

### Vote Values
- **Super Like** (❤️): +2 points
- **Like** (👍): +1 point
- **OK** (✋): 0 points
- **Dislike** (👎): -100 points (soft veto)
- **Veto** (❌): Disqualified (hard constraint, e.g., allergy)

### Selection Process
1. **Nomination**: Head of Household or AI selects 15-20 candidate recipes
2. **Deliberation**: Family members vote asynchronously
3. **Resolution**: Algorithm calculates scores and selects top N recipes
4. **Ratification**: HoH schedules winning recipes to specific days

### Why This Works
- **Prevents polarization**: Disliked recipes score negatively, even if some love them
- **Rewards consensus**: Recipes that everyone is "OK" with often win over divisive choices
- **Respects strong preferences**: Allergies/restrictions get absolute veto power

## 🔐 Privacy & Security

- **End-to-End Encryption**: CloudKit uses Apple's encryption for all synced data
- **No Account Creation**: Uses existing iCloud credentials
- **Local-First**: All data stored locally with optional cloud sync
- **Secure Invitations**: CloudKit handles invitation verification
- **No Third-Party Tracking**: Zero analytics or tracking SDKs

## 🛣️ Roadmap

### Phase 1: Foundation ✅
- [x] SwiftData models
- [x] CloudKit integration
- [x] Voting algorithm
- [x] Basic UI components

### Phase 2: Core Features (Current)
- [ ] Complete recipe entry forms
- [ ] Drag-and-drop calendar
- [ ] AI recipe generation (full implementation)
- [ ] Shopping list generation from meal plans
- [ ] Budget tracking dashboard

### Phase 3: Polish
- [ ] Recipe image upload and storage
- [ ] Nutrition information display
- [ ] Meal history and favorites
- [ ] Recipe import from URLs (web scraping)
- [ ] Push notifications for voting reminders

### Phase 4: Advanced
- [ ] Pantry inventory tracking
- [ ] Expiration date alerts
- [ ] Grocery store API integration (Kroger, Instacart)
- [ ] Meal prep planning
- [ ] Leftovers tracking

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow Swift API Design Guidelines
- Use SwiftLint for consistency
- Write unit tests for business logic
- Comment complex algorithms

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Voting Theory**: Inspired by Condorcet methods and social choice theory
- **Design**: Tinder's swipe interface for intuitive voting
- **APIs**: OpenAI for AI capabilities, Spoonacular for recipe data
- **Apple**: SwiftUI, SwiftData, and CloudKit frameworks

## 📧 Contact

- **GitHub**: [@yourusername](https://github.com/yourusername)
- **Email**: hello@familyfeast.app
- **Website**: [familyfeast.app](https://familyfeast.app)

---

**Made with ❤️ for families who want to end dinner arguments**