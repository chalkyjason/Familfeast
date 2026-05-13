# MealMeld Release Readiness Review Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Review `MealMeld` for correctness, crashes, security/privacy issues, App Store risks, and release gaps before uploading a build to TestFlight with Fastlane.

**Architecture:** This review is repo-first and risk-ordered. Start by proving the project builds and tests cleanly, then inspect the highest-risk surfaces in order: secrets/networking, auth/storage, CloudKit/data integrity, crash-prone UI code, and finally App Store/TestFlight release configuration.

**Tech Stack:** Swift 5.9, SwiftUI, SwiftData, CloudKit, Sign in with Apple, OSLog, Xcode project targets, App Store Connect metadata, Fastlane/TestFlight workflow.

---

### Task 1: Baseline Build, Test, and Project Inventory

**Files:**
- Inspect: `Package.swift`
- Inspect: `MealMeld.xcodeproj/project.pbxproj`
- Inspect: `FamilyFeast.xcodeproj/project.pbxproj`
- Inspect: `Sources/App/MealMeldApp.swift`
- Inspect: `Tests/VotingAlgorithmTests.swift`

- [ ] **Step 1: Confirm the intended shipping target and scheme**

Run:
```bash
rg -n "PRODUCT_BUNDLE_IDENTIFIER|PRODUCT_NAME|INFOPLIST_FILE|CODE_SIGN_ENTITLEMENTS" MealMeld.xcodeproj/project.pbxproj FamilyFeast.xcodeproj/project.pbxproj
```

Expected:
- One clear production app target for TestFlight
- Bundle ID matches `docs/APP_STORE_SUBMISSION.md`
- Entitlements file resolves to `MealMeld.entitlements`

- [ ] **Step 2: Run package-level tests immediately**

Run:
```bash
swift test
```

Expected:
- Tests pass with no compile errors
- Any failure becomes a blocking correctness issue before release work continues

- [ ] **Step 3: Run simulator build for the shipping project**

Run:
```bash
xcodebuild -project MealMeld.xcodeproj -scheme MealMeld -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected:
- Clean build with no warnings worth escalating to release blockers
- If the scheme does not exist or the wrong project is wired, fix project selection before deeper review

- [ ] **Step 4: Record baseline findings**

Capture:
- Build failures
- Test failures
- Duplicate project drift between `MealMeld.xcodeproj` and `FamilyFeast.xcodeproj`
- Missing scheme/signing configuration

### Task 2: Secrets, Configuration, and Release Artifact Audit

**Files:**
- Inspect: `Sources/Utilities/Config.swift`
- Inspect: `Sources/Services/AIService.swift`
- Inspect: `README.md`
- Inspect: `docs/APP_STORE_SUBMISSION.md`
- Inspect: `MealMeld.entitlements`

- [ ] **Step 1: Verify no production secret is embedded in the app bundle**

Review:
- `Sources/Utilities/Config.swift`
- Xcode project build settings for any `OpenAIKey` or similar plist injection

Check:
- `Config.openAIKey` currently allows `Bundle.main.infoDictionary?["OpenAIKey"]`

Expected:
- No real OpenAI key in source control, plist files, or committed build settings
- If a client-side OpenAI key is required for shipping, treat that as a release-blocking security flaw

- [ ] **Step 2: Search the repo for secret-like material and unsafe config**

Run:
```bash
rg -n "OPENAI_API_KEY|OpenAIKey|SPOONACULAR|API_KEY|Bearer |sk-[A-Za-z0-9]|BEGIN PRIVATE KEY|password|secret" .
```

Expected:
- Only placeholder references, docs, or environment-based examples
- No live credentials or accidental copies in docs/screenshots/project files

- [ ] **Step 3: Validate release claims against actual implementation**

Compare:
- `README.md`
- `docs/APP_STORE_SUBMISSION.md`
- `Sources/Utilities/Config.swift`
- `Sources/Services/AIService.swift`

Expected:
- Privacy/feature claims match the shipped code
- Remove or revise any claim that the app has “no accounts,” “no third-party content,” or stronger privacy guarantees than the code actually supports

### Task 3: Network, AI, and Privacy Risk Review

**Files:**
- Inspect: `Sources/Services/AIService.swift`
- Inspect: `Sources/Utilities/Logger+Extension.swift`
- Inspect: `Sources/Views/Recipe/AISuggestionsView.swift`
- Inspect: `Sources/Views/Recipe/RecipeURLImportView.swift`
- Inspect: `Sources/Views/Recipe/AddRecipeView.swift`

- [ ] **Step 1: Review outbound data flows to third parties**

Inspect in `Sources/Services/AIService.swift`:
- `suggestRecipes`
- `generateRecipeFromDescription`
- `parseIngredients`
- `parseRecipeFromURL`
- `parseRecipeFromVideoURL`
- `sendChatCompletion`

Expected:
- Explicit understanding of what user/family data can leave the device
- Determine whether recipe URLs, imported page contents, and dietary preferences are transmitted to OpenAI

- [ ] **Step 2: Check for privacy-policy mismatches**

Decide:
- If OpenAI requests are enabled in production, App Privacy and review answers must disclose third-party data handling accurately
- `docs/APP_STORE_SUBMISSION.md` currently says `third-party content: no`; verify whether URL-imported recipe pages or AI outputs make that answer misleading

- [ ] **Step 3: Review logging for sensitive data leakage**

Run:
```bash
rg -n "Logger\\.|print\\(" Sources
```

Expected:
- No API keys, raw request bodies, personal data, or full third-party error payloads logged in release builds
- In `AIService`, review the logged error body from failed OpenAI responses as a potential data leak

- [ ] **Step 4: Assess architecture risk of client-side AI API usage**

Decision:
- If `AIService` talks directly to OpenAI from the client with a bearer key, recommend moving AI calls behind a server you control before App Store release
- If not moving now, explicitly classify this as a high-severity accepted risk

### Task 4: Authentication, Identity Storage, and Account Lifecycle Review

**Files:**
- Inspect: `Sources/Services/AuthenticationService.swift`
- Inspect: `Sources/Views/Auth/SignInView.swift`
- Inspect: `docs/APP_STORE_SUBMISSION.md`

- [ ] **Step 1: Audit Sign in with Apple state management**

Review in `Sources/Services/AuthenticationService.swift`:
- `handleSignInResult`
- `checkCredentialState`
- `signOut`
- `save`
- `loadStoredCredentials`

Expected:
- Correct handling of revoked credentials
- No reliance on stale local auth state after account removal

- [ ] **Step 2: Evaluate storage choice for Apple identity attributes**

Check:
- `userID`, `displayName`, and `email` are stored in `UserDefaults`

Expected:
- Decide whether `userID` in `UserDefaults` is acceptable for this app
- If stronger protection is needed, migrate sensitive identity fields to Keychain or reduce retained data

- [ ] **Step 3: Check App Store review statements about login**

Expected:
- The review notes say “No login required” while the app includes Sign in with Apple and iCloud identity usage
- Clarify whether sign-in is optional, implicit, or required for sync features so review notes are accurate

### Task 5: CloudKit, Persistence, and Entitlements Review

**Files:**
- Inspect: `Sources/Services/CloudKitService.swift`
- Inspect: `Sources/App/MealMeldApp.swift`
- Inspect: `Sources/Models/FamilyGroup.swift`
- Inspect: `MealMeld.entitlements`
- Inspect: `Tests/VotingAlgorithmTests.swift`

- [ ] **Step 1: Verify CloudKit runtime behavior matches the data layer**

Compare:
- `CloudKitService.activateCloudKit()`
- `MealMeldApp` model container configuration

Expected:
- `CloudKitService` activates a CloudKit container
- `MealMeldApp` uses `ModelConfiguration(..., cloudKitDatabase: .none)`
- Flag any mismatch between “real-time CloudKit sync” product claims and actual persistence wiring

- [ ] **Step 2: Review CloudKit error handling and offline fallback**

Inspect:
- Retry logic in `performWithRetry`
- `checkAccountStatus`
- Share creation and record CRUD methods

Expected:
- Clear handling for unavailable iCloud, rate limiting, permission failures, and first-launch offline state
- No user-visible dead ends when CloudKit is unavailable

- [ ] **Step 3: Validate entitlements against actual capabilities**

Run:
```bash
plutil -p MealMeld.entitlements
```

Expected:
- iCloud container ID matches code and App Store metadata
- Sign in with Apple entitlement is present if the shipping target exposes that capability

### Task 6: Crash, Concurrency, and Error-Handling Review

**Files:**
- Inspect: `Sources/App/MealMeldApp.swift`
- Inspect: `Sources/Views/Voting/VotingSessionView.swift`
- Inspect: `Sources/Views/Family/FamilySettingsView.swift`
- Inspect: `Sources/Views/MealPlanning/MealPlanningView.swift`
- Inspect: `Sources/Views/Recipe/CookingModeView.swift`
- Inspect: `Sources/Views/Onboarding/OnboardingView.swift`
- Inspect: `Sources/Views/Shopping/ShoppingListView.swift`

- [ ] **Step 1: Enumerate all force-crash sites**

Run:
```bash
rg -n "try!|fatalError\\(|preconditionFailure\\(|assertionFailure\\(" Sources
```

Expected:
- Every `try!` and `fatalError` is reviewed as a release risk
- Current hotspots already visible include `MealMeldApp.swift`, `VotingSessionView.swift`, `FamilySettingsView.swift`, `MealPlanningView.swift`, and `CookingModeView.swift`

- [ ] **Step 2: Enumerate all unstructured error swallowing**

Run:
```bash
rg -n "print\\(|catch \\{|catch$" Sources
```

Expected:
- Replace silent or console-only failures with user-safe handling and structured logging
- Determine which failures should surface actionable UI messaging

- [ ] **Step 3: Review task/concurrency boundaries**

Inspect:
- `Task {}` use in onboarding, family settings, AI views, and app startup

Expected:
- No UI state mutation races
- No startup work that can outlive view lifetime without cancellation strategy

### Task 7: App Store Compliance and Metadata Accuracy Review

**Files:**
- Inspect: `docs/APP_STORE_SUBMISSION.md`
- Inspect: `README.md`
- Inspect: `MealMeld.entitlements`
- Inspect: shipping screenshots in `docs/screenshots/appstore/`

- [ ] **Step 1: Verify privacy answers against the codebase**

Review:
- Data collected and transmitted
- Sign in with Apple usage
- CloudKit identity handling
- OpenAI/recipe URL import behavior

Expected:
- `data_collected: User ID` may be incomplete if third-party AI requests send user-provided content
- Update App Privacy answers before TestFlight if needed

- [ ] **Step 2: Verify encryption/export compliance answers**

Expected:
- `uses_encryption: no` is likely incorrect for an app using HTTPS and Apple platform cryptography
- Re-answer export compliance truthfully in App Store Connect instead of relying on this draft value

- [ ] **Step 3: Validate review notes and screenshots**

Expected:
- Review notes describe the real first-run flow
- Screenshots match the shipping app name/branding and current UI
- Remove unsupported claims such as “works fully in local-only mode” if any core flow depends on cloud/auth

### Task 8: Fastlane and TestFlight Preflight

**Files:**
- Inspect: `docs/APP_STORE_SUBMISSION.md`
- Inspect: Xcode signing/build settings in `MealMeld.xcodeproj/project.pbxproj`
- Inspect: any future `fastlane/Fastfile` or `fastlane/Appfile` if added

- [ ] **Step 1: Confirm Fastlane assets actually exist**

Run:
```bash
rg --files -g 'fastlane/**' -g 'Fastfile' -g 'Appfile'
```

Expected:
- If no Fastlane files exist, create that as a release-prep task rather than assuming upload automation is ready

- [ ] **Step 2: Verify archive prerequisites**

Check:
- Bundle identifier
- Version and build number strategy
- Signing team/profiles
- App icon, launch assets, support URL, privacy URL

Expected:
- No missing archive metadata or signing blockers before first `fastlane beta`

- [ ] **Step 3: Define the pre-upload command sequence**

Run, once review fixes are complete:
```bash
swift test
xcodebuild -project MealMeld.xcodeproj -scheme MealMeld -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Then:
- Archive locally in Xcode or via `xcodebuild archive`
- Upload with Fastlane only after metadata/privacy answers are corrected

### Task 9: Findings Triage and Remediation Queue

**Files:**
- Create: `docs/reviews/2026-05-08-release-audit-findings.md`

- [ ] **Step 1: Classify findings by severity**

Buckets:
- Release blocker
- Must fix before external TestFlight
- Should fix before App Review
- Post-1.0 improvement

- [ ] **Step 2: Write concrete remediation tickets**

Each finding must include:
- File path
- Risk description
- User impact
- Proposed fix
- Verification command or manual retest flow

- [ ] **Step 3: Re-run baseline verification after fixes**

Minimum reruns:
```bash
swift test
xcodebuild -project MealMeld.xcodeproj -scheme MealMeld -destination 'platform=iOS Simulator,name=iPhone 16' build
```

Expected:
- No new regressions introduced by the release hardening pass
