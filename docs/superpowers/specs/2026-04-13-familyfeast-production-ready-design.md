# FamilyFeast Production-Ready Design Spec

**Date:** 2026-04-13
**Status:** Approved
**Goal:** Make FamilyFeast production-ready with Google Ads, premium subscriptions, and competitive differentiation — while keeping data on-device and costs minimal.

---

## 1. Architecture

### Current Stack (Keep)

- **UI:** SwiftUI
- **Persistence:** SwiftData — all data stays on-device
- **Family Sync:** CloudKit (free, encrypted, Apple-hosted)
- **AI:** Apple Foundation Models (on-device LLM, iOS 26+) — replaces OpenAI entirely
- **Minimum Deployment:** iOS 26 (required for Foundation Models framework)
- **Dependencies:** Zero third-party packages (except AdMob SDK, to be added)

### Changes

| Area | Current | Target |
|------|---------|--------|
| AI engine | OpenAI GPT-4o-mini (cloud API) | Apple Foundation Models (on-device, free) |
| API key storage | Environment variables | Eliminated — no API keys needed |
| AI access | Unrestricted | Free: 3/week, Premium: unlimited |
| Deployment target | iOS 17 | iOS 26 (for Foundation Models) |
| Ads | None | Google AdMob banners on Dashboard + RecipeListView |
| Subscriptions | None | StoreKit 2 ($4.99/mo or $39.99/yr) |
| Error handling | Logged to console | User-facing alerts |
| Loading states | Missing in many views | Skeleton/spinner for all async ops |

### Data Strategy

- SwiftData stores everything locally (works offline — critical for grocery store use)
- CloudKit CKShare for family sync (already scaffolded in CloudKitService)
- No third-party servers, no database costs, no backend
- Privacy pitch: "Your family's data never leaves Apple's ecosystem"

---

## 2. Monetization

### 2.1 Google AdMob Integration

**SDK:** Google Mobile Ads SDK via Swift Package Manager (SPM)

**Ad Placement Rules:**
- Banner ads on DashboardView (bottom of scroll) — YES
- Banner ads on RecipeListView (between filter chips and list) — YES
- NO ads in VotingSessionView (disrupts core experience)
- NO ads in CookingModeView (safety — hands are busy)
- NO ads in onboarding (bad first impression)
- NO interstitial or rewarded ads at launch (too aggressive for a family app)

**Implementation:**
- Create `AdBannerView` — UIViewRepresentable wrapping GADBannerView
- Create `AdManager` service — handles initialization, ad unit IDs, consent (ATT framework)
- Show ads only for free-tier users (check subscription status)
- Test with Google's test ad unit IDs during development
- Production ad unit IDs stored in a plist (not hardcoded)

**App Tracking Transparency (ATT):**
- Request ATT permission on first launch after onboarding
- If denied, show non-personalized ads (still revenue, just lower CPM)
- Add `NSUserTrackingUsageDescription` to Info.plist

### 2.2 StoreKit 2 Subscriptions

**Products:**
- `com.familyfeast.premium.monthly` — $4.99/month
- `com.familyfeast.premium.annual` — $39.99/year (save 33%)

**Implementation:**
- Create `SubscriptionManager` (ObservableObject) using StoreKit 2's `Product` and `Transaction` APIs
- Listen for `Transaction.updates` to handle renewals, cancellations, refunds
- Store entitlement status in `@AppStorage` for quick UI checks, verify with StoreKit on launch
- No RevenueCat — StoreKit 2 handles everything natively

**Paywall UI:**
- Present when user hits a premium gate (51st recipe, 4th AI suggestion, etc.)
- Show feature comparison table (free vs premium)
- Highlight annual savings
- "Restore Purchases" button prominently displayed
- Family Sharing support via StoreKit 2's `isEligibleForIntroOffer`

### 2.3 Free vs Premium Tier

| Feature | Free | Premium |
|---------|------|---------|
| Family voting | Unlimited | Unlimited |
| Recipes | Up to 50 | Unlimited |
| AI suggestions (on-device) | 3/week | Unlimited |
| Active meal sessions | 2 | Unlimited |
| Active shopping lists | 1 | Unlimited |
| Ads | Banner ads | Ad-free |
| Cooking mode | Yes | Yes |
| Recipe URL import | Yes | Yes |
| Nutrition tracking | Basic (calories) | Full (macros, fiber, sodium) |
| Export data | No | Yes |
| Multiple family groups | No (1 group) | Yes |
| Recipe image upload | No | Yes |

**Usage Tracking (for free-tier limits):**
- Store `aiSuggestionsUsedThisWeek` and `weekStartDate` in SwiftData
- Reset count when current date > weekStartDate + 7 days
- Recipe count checked via `@Query` count
- Session/list counts checked via `@Query` with active status filter

---

## 3. Production Readiness Fixes

### 3.1 P0 — Must Ship

**3.1.1 Google AdMob SDK**
- Add `google-mobile-ads` via SPM
- Create `AdBannerView` (UIViewRepresentable)
- Create `AdManager` actor for initialization and consent
- Place banners in DashboardView and RecipeListView
- Add ATT permission request
- Add `GADApplicationIdentifier` to Info.plist
- Add `NSUserTrackingUsageDescription` to Info.plist

**3.1.2 StoreKit 2 Subscriptions**
- Create `SubscriptionManager` (ObservableObject)
- Define products in App Store Connect
- Create `PaywallView` with tier comparison
- Add restore purchases flow
- Gate features behind `SubscriptionManager.isPremium`
- Handle `Transaction.updates` for renewals/cancellations

**3.1.3 Remove DashboardView 2.swift**
- Delete `Sources/Views/Dashboard/DashboardView 2.swift` (duplicate artifact)

**3.1.4 Replace OpenAI with Apple Foundation Models**
- Rewrite `AIService` to use `FoundationModels` framework instead of OpenAI HTTP API
- Use `LanguageModelSession` for text generation (recipe suggestions, ingredient parsing, meal plans)
- Use `@Generable` macro on response structs for structured output (typed recipe suggestions)
- Add `SystemPrompt` with FamilyFeast context (dietary restrictions, cuisine preferences, budget)
- Use `GenerationOptions` to control temperature/token limits per use case
- Check device capability with `SystemLanguageModel.default.availability` before showing AI features
- Handle `.notAvailable` gracefully — show "AI requires iPhone 16 or newer" message
- Remove OpenAI API key references, `URLSession` calls, and `API_CONFIGURATION.md`
- Delete `KeychainService` requirement (no API keys needed)
- Bump deployment target to iOS 26 in Package.swift and project settings
- **Result:** Zero API costs, zero network dependency for AI, data never leaves device

**3.1.5 Free-Tier Limits**
- Add `UsageTracker` model to SwiftData (aiUsageCount, weekStart, recipeCount checks)
- Enforce limits in AIService calls and recipe creation (on-device AI is free to run, but limit keeps premium attractive)
- Show paywall when limit hit

**3.1.6 Fix Stubbed Features**
- Budget Settings: Simple form to set weekly/monthly family budget, stored on FamilyGroup
- Notifications: Local notifications for meal prep reminders, voting deadlines (UNUserNotificationCenter)
- Export Data: Export recipes + shopping lists as JSON or CSV (ShareLink)
- Sync Status: Show CloudKit account status, last sync time, pending changes
- Send Feedback: Open mailto: link or in-app feedback form
- Edit Family Name: Enable the disabled edit button, simple text field update

**3.1.7 Error Handling UI**
- Create reusable `.errorAlert(error:)` view modifier
- Surface network errors, CloudKit failures, AI service errors as user-facing alerts
- Add retry buttons where appropriate

**3.1.8 Input Validation**
- Recipe title: required, max 200 chars
- Family member name: required, max 100 chars
- Budget: positive number, max reasonable value
- Ingredients: at least 1 required for recipe save
- Session dates: end must be after start

### 3.2 P1 — Should Ship

**3.2.1 Complete CloudKit Invite Flow**
- Implement `sendInvite()` in FamilySettingsView
- Create CKShare from family zone
- Add participant by email
- Present UICloudSharingController for share management
- Handle incoming share acceptance in SceneDelegate/AppDelegate

**3.2.2 Recipe Image Support**
- Add PhotosPicker (iOS 16+) to AddRecipeView and RecipeDetailView
- Compress images before storing (max 1MB, JPEG 0.7 quality)
- Store in SwiftData's `imageData` field (already has `.externalStorage`)
- Show images in RecipeCard, RecipeDetailView, VotingCardView

**3.2.3 Loading States**
- Add `ProgressView` or skeleton views for:
  - AI suggestion generation
  - CloudKit sync operations
  - Recipe list initial load
  - Shopping list creation from meal session

**3.2.4 Accessibility**
- Add `accessibilityLabel` to voting cards (recipe name, description)
- Add `accessibilityAction` for voting (alternative to swipe)
- Ensure cooking mode works with VoiceOver (step announcements)
- Dynamic Type support verification
- Minimum touch targets (44x44pt) on all interactive elements

**3.2.5 Onboarding Improvements**
- Add feature highlight pages (voting, AI, shopping lists)
- Brief explanation of voting types (superlike through veto)
- Optional dietary restriction setup during onboarding

**3.2.6 Analytics (Privacy-Respecting)**
- Track feature usage counts locally in SwiftData (not sent anywhere)
- Metrics: recipes created, votes cast, AI suggestions used, sessions completed
- Used to inform product decisions, shown in a developer-only debug screen
- No third-party analytics SDK

**3.2.7 App Icon and Branding**
- Professional app icon (family/food themed)
- Launch screen with app logo
- Consistent color palette across all views
- App Store screenshots (6.7" and 6.1" iPhone sizes minimum)

### 3.3 P2 — Competitive Edge

**3.3.1 Widget (WidgetKit)**
- Small widget: Today's meal name
- Medium widget: Today's meals (breakfast/lunch/dinner)
- Uses SwiftData App Group for shared data access

**3.3.2 Siri Shortcuts**
- "What's for dinner?" — reads today's scheduled dinner
- "Start voting" — opens voting session
- App Intents framework

**3.3.3 Meal History and Ratings**
- New view showing past completed sessions
- Family rating after each meal (1-5 stars per member)
- "Cook again" button to re-add to a new session
- Track `timesCooked` and `averageRating` (fields already exist on Recipe)

**3.3.4 Smart Variety Engine**
- Track last 30 days of scheduled meals
- AI suggestions exclude recently cooked recipes
- Voting algorithm weights down recently eaten cuisines
- "Try something new" mode that boosts unfamiliar cuisines

**3.3.5 Drag-and-Drop Meal Calendar**
- Replace static weekly view with interactive calendar
- Drag recipes between days/meal slots
- Long-press to swap meals
- Uses SwiftUI's `.draggable()` and `.dropDestination()` modifiers

---

## 4. Competitive Positioning

### Market Context

- Market size: ~$2.71B (2026), growing to $6.77B by 2034
- Closest competitor: FamilyPlate (web-only, beta, ~500 families, 3-tier voting)
- Strongest overall: Ollie ($9.99/mo, 90K users, AI but NO voting)
- Established but no family features: Mealime, Paprika, Plan to Eat

### FamilyFeast Differentiators

1. **Only native iOS app with AI + family voting + per-member dietary profiles**
2. **5-tier voting with Borda Count + Schulze consensus** (most sophisticated in market)
3. **Per-member allergens and cuisine preferences** (competitors do household-level)
4. **Child roles** with age-appropriate permissions (unique)
5. **Privacy-first** — iCloud ecosystem only, no third-party servers, AI runs on-device
6. **Offline-first** — works in grocery stores with no signal (including AI suggestions)
7. **Zero API costs** — on-device AI means no per-user backend costs
8. **Undercuts Ollie by 50%** ($4.99 vs $9.99/mo)

### Positioning Statement

"The meal planning app where everyone gets a vote."

Against FamilyPlate: Native iOS, richer voting (5 vs 3 tiers), offline support, iCloud privacy.
Against Ollie: "Ollie decides for your family. FamilyFeast lets your family decide together."
Against Mealime/Paprika: "They plan for one person. We plan for your whole family."

### User Pain Points We Solve

| Pain Point | How FamilyFeast Solves It |
|------------|--------------------------|
| "One person decides, everyone else complains" | Democratic voting with consensus algorithm |
| "My kid is allergic but my spouse isn't" | Per-member dietary profiles |
| "Same meals every week" | AI variety + voting history tracking |
| "App doesn't work in the grocery store" | Offline-first with SwiftData |
| "I don't trust where my data goes" | iCloud only, no third-party servers |
| "Too expensive for a meal app" | Generous free tier, premium at $4.99/mo |

---

## 5. Cost Analysis (Developer)

### Ongoing Costs

| Item | Free Tier Users | Premium Users | Your Cost |
|------|----------------|---------------|-----------|
| Data storage | SwiftData (on-device) | SwiftData + CloudKit | $0 (Apple free tier) |
| Family sync | CloudKit | CloudKit | $0 (1PB free) |
| AI suggestions | On-device (Foundation Models) | On-device (Foundation Models) | $0 (runs on user's hardware) |
| Ad revenue | ~$1-3 eCPM | N/A (ad-free) | Revenue, not cost |
| App Store | — | 15-30% cut of subscriptions | Percentage, not fixed cost |

**Total ongoing infrastructure cost: $0.** All computation runs on the user's device. All sync goes through Apple's free CloudKit tier. You pay nothing per user.

### Revenue Projection (Conservative)

At 1,000 premium subscribers ($4.99/mo, Apple takes 15% after year 1):
- Monthly: ~$4,241
- Annual: ~$50,892

Ad revenue from free users (assuming 10K MAU, 2 ad impressions/session, $2 eCPM):
- Monthly: ~$400-800

**AI cost at scale: $0.** On-device AI runs on the user's iPhone — no API calls, no tokens to pay for, scales infinitely with zero marginal cost.

---

## 6. App Store Readiness Checklist

- [ ] App icon (1024x1024)
- [ ] Launch screen
- [ ] Screenshots (6.7", 6.1" iPhone)
- [ ] App Store description and keywords
- [ ] Privacy policy URL
- [ ] Terms of service URL
- [ ] App privacy labels (data collection disclosure)
- [ ] ATT usage description
- [ ] Age rating (4+ — family app)
- [ ] In-app purchase configuration in App Store Connect
- [ ] Review notes for Apple (explain AI features, family sharing)
- [ ] Bundle ID and signing configured
- [ ] Minimum deployment target: iOS 17.0

---

## 7. File Structure Changes

### New Files to Create

```
Sources/
  Services/
    AdManager.swift              — Google AdMob initialization and consent
    SubscriptionManager.swift    — StoreKit 2 subscription management
    NotificationService.swift    — Local notification scheduling
  Models/
    UsageTracker.swift           — Free-tier usage tracking
  Views/
    Ads/
      AdBannerView.swift         — UIViewRepresentable for GADBannerView
    Subscription/
      PaywallView.swift          — Premium tier comparison and purchase
      SubscriptionSettingsView.swift — Manage subscription, restore purchases
    Settings/
      BudgetSettingsView.swift   — Family budget configuration
      NotificationSettingsView.swift — Notification preferences
      ExportDataView.swift       — Export recipes/lists as JSON/CSV
      SyncStatusView.swift       — CloudKit sync status display
      FeedbackView.swift         — In-app feedback form
  Utilities/
    ErrorHandling.swift          — Reusable error alert modifier
    InputValidation.swift        — Form validation helpers
```

### Files to Modify

```
Sources/App/FamilyFeastApp.swift          — Add AdMob init, SubscriptionManager env
Sources/Views/Dashboard/DashboardView.swift — Add ad banner, premium gates
Sources/Views/Recipe/RecipeListView.swift   — Add ad banner
Sources/Views/Recipe/AISuggestionsView.swift — Add usage limit check
Sources/Views/Recipe/AddRecipeView.swift    — Add recipe count check, image picker
Sources/Views/Family/FamilySettingsView.swift — Fix stubbed buttons, add subscription
Sources/Services/AIService.swift            — Rewrite to use Foundation Models (remove OpenAI)
Package.swift                               — Add Google Mobile Ads dependency, bump to iOS 26
```

### Files to Delete

```
Sources/Views/Dashboard/DashboardView 2.swift  — Duplicate artifact
API_CONFIGURATION.md                            — No longer needed (no external APIs)
```
