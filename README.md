# MealMeld

**A Consensus-Driven Meal Planning App for iOS**

MealMeld turns "What's for dinner?" from a one-person chore into a family vote. Add recipes, run a voting session, and let a Borda Count consensus algorithm pick meals everyone can live with.

![iOS](https://img.shields.io/badge/iOS-17.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-green)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Features

- **Democratic Voting** — Tinder-style swipe interface. Borda Count consensus prevents polarizing picks.
- **Recipe Library** — Add recipes manually, scale ingredients by serving count, and follow step-by-step cooking mode with a built-in countdown timer.
- **Smart Shopping Lists** — Auto-generated from your finalized meal plans, organized by aisle, with budget tracking.
- **Weekly Meal Calendar** — Schedule meals across the week with session management.
- **Dietary Profiles** — Per-member restrictions (vegetarian, vegan, gluten-free, keto) and allergen alerts. Automatic conflict warnings during planning.
- **Budget Management** — Cost estimation per recipe and meal plan, with alerts when approaching limits.
- **Sign in with Apple** — Optional sign-in for identity.

## Architecture

- **Frontend**: SwiftUI with iOS 17+ features
- **Data Persistence**: SwiftData
- **Project Generation**: XcodeGen from `project.yml`
- **Design Pattern**: MVVM with service-oriented architecture

## Getting Started

### Prerequisites

- Xcode 16.0+
- iOS 17.0+ SDK
- Apple Developer Account (for device builds)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/chalkyjason/Familfeast.git
   cd Familfeast
   ```
2. Open in Xcode:
   ```bash
   open MealMeld.xcodeproj
   ```
   If you modify `project.yml`, install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and run `xcodegen generate`.
3. Configure signing: select the MealMeld target, go to "Signing & Capabilities", and select your development team.
4. Build and run on a simulator or device (Cmd+R).

## Testing

```bash
# Via Xcode
Cmd+U

# Via command line
xcodebuild test -project MealMeld.xcodeproj -scheme MealMeld -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Voting Algorithm

MealMeld uses a Modified Borda Count to reach consensus.

### Vote values
- **Super Like**: +2
- **Like**: +1
- **OK**: 0
- **Dislike**: -100 (soft veto)
- **Veto**: disqualified (hard constraint, e.g. allergy)

### Selection process
1. **Nomination**: family chooses candidate recipes.
2. **Deliberation**: family members vote asynchronously via the swipe UI.
3. **Resolution**: the algorithm scores votes and picks top N.
4. **Ratification**: schedule winning recipes to specific days.

## Privacy

- **Local-first**: all data stored on-device with SwiftData.
- **No third-party tracking**: zero analytics or tracking SDKs.
- **Sign in with Apple**: optional; stores only the Apple-issued user ID and a display name locally.

## Roadmap

### Phase 1 — Foundation
- [x] SwiftData models
- [x] Voting algorithm
- [x] Voting UI (Tinder-style swipe)
- [x] End-to-end meal session flow
- [x] Shopping list generation from meal plans

### Phase 2 — Core Features
- [x] Recipe entry forms
- [x] Recipe scaling
- [x] Nutrition info display
- [x] Step-by-step cooking mode with timer
- [x] Dietary profiles (restrictions, allergens, cuisines)
- [x] Dietary conflict warnings during planning
- [ ] Drag-and-drop calendar
- [ ] Budget tracking dashboard

### Phase 3 — Polish
- [ ] Recipe image upload
- [ ] Meal history and favorites
- [ ] Push notifications for voting reminders

### Phase 4 — Future (deferred)
- [ ] CloudKit-backed family sync and invitations
- [ ] Recipe URL import
- [ ] AI recipe suggestions
- [ ] Pantry inventory tracking
- [ ] Grocery store API integration

## License

MIT. See [LICENSE](LICENSE).

## Contact

- GitHub: [@chalkyjason](https://github.com/chalkyjason)
