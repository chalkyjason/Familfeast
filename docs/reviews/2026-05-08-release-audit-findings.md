# MealMeld Release Audit Findings

Date: 2026-05-08

## Verification Evidence

- `swift test`
  - Failed.
  - Key failures:
    - `Sources/Utilities/Theme.swift:10-11` uses `Color(uiColor:)`, which does not compile for the package's macOS target.
    - Multiple iOS-only APIs are referenced from package sources, including `UIImage`, `UIImpactFeedbackGenerator`, `.navigationBarTrailing`, and `.insetGrouped`.
  - Additional warning:
    - `Sources/Assets.xcassets` is unhandled by `Package.swift`.

- `xcodebuild -project MealMeld.xcodeproj -scheme MealMeld -destination 'platform=iOS Simulator,name=iPhone 16' build`
  - Blocked by local CoreSimulator service issues, so it did not provide reliable project-level build evidence.

- `xcodebuild -project MealMeld.xcodeproj -scheme MealMeld -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`
  - Did not complete within the session window, so no success claim is made from it.

## Findings

### Release Blocker

1. Direct client-side OpenAI access exposes your production API key and sends user data to a third party from the app binary.
   - Evidence: [Sources/Utilities/Config.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Utilities/Config.swift:7) reads `OPENAI_API_KEY` from env or `OpenAIKey` from `Info.plist`; [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:269) sends a bearer token directly from the client.
   - Impact: Any shipped key can be extracted from the app or observed at runtime, abused outside your quota expectations, and rotated only after compromise. This is not acceptable for a public App Store build.
   - Privacy impact: recipe prompts, ingredient lists, budgets, dietary restrictions, URL imports, and webpage snippets are transmitted off-device to OpenAI. See [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:21), [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:160), and [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:237).
   - Required fix: move AI requests behind a server you control, issue server-side credentials only, and update privacy disclosures accordingly.

2. The repo does not currently prove a shippable build; the package target fails compilation due to cross-platform drift.
   - Evidence: `swift test` failed on:
     - [Sources/Utilities/Theme.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Utilities/Theme.swift:10)
     - [Sources/Views/Shopping/ShoppingListView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Shopping/ShoppingListView.swift:47)
     - [Sources/Views/Voting/VotingCardView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Voting/VotingCardView.swift:107)
     - [Sources/Views/Recipe/RecipeListView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Recipe/RecipeListView.swift:196)
   - Root cause: [Package.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Package.swift:6) declares both iOS and macOS support, but the source tree uses many iOS-only APIs without conditional compilation.
   - Impact: the package manifest is misleading, tests are not a reliable release gate, and CI/TestFlight automation built around package verification will fail or provide false confidence.
   - Required fix: either remove macOS from `Package.swift`, split shared code from app UI, or guard iOS-only UI code with platform conditionals and resource declarations.

### Must Fix Before External TestFlight

3. App Store privacy and review answers are materially inaccurate for the code that is present.
   - Evidence:
     - `No accounts to create` and strong local-first privacy language in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:54)
     - `No login required` in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:92)
     - `data_collected: User ID` only in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:103)
     - `uses_encryption: no` in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:107)
     - `third-party content: no` in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:117)
   - Why this is wrong:
     - The app has Sign in with Apple entitlement: [MealMeld.entitlements](/Users/jasonchalky/Documents/GitHub/Familfeast/MealMeld.entitlements:10)
     - The app stores Apple identity details locally: [Sources/Services/AuthenticationService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AuthenticationService.swift:96)
     - The app sends user-provided content to OpenAI: [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:283)
     - The app imports third-party recipe and video URLs: [Sources/Views/Recipe/RecipeURLImportView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Recipe/RecipeURLImportView.swift:27)
   - Impact: inaccurate App Privacy or review answers are an App Review rejection risk.

4. The marketed CloudKit sync behavior does not match the actual SwiftData configuration.
   - Evidence:
     - Product copy promises real-time CloudKit sync in [docs/APP_STORE_SUBMISSION.md](/Users/jasonchalky/Documents/GitHub/Familfeast/docs/APP_STORE_SUBMISSION.md:42)
     - `CloudKitService` is activated in [Sources/App/MealMeldApp.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/App/MealMeldApp.swift:28)
     - But the SwiftData store is explicitly configured with `cloudKitDatabase: .none` in [Sources/App/MealMeldApp.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/App/MealMeldApp.swift:54)
   - Impact: the app description promises sync behavior the primary persistence layer is not actually wired to provide.
   - Required fix: either complete the sync architecture or remove/soften the sync claims until it is real.

5. Family invitation flow is stubbed out while docs claim secure collaboration features.
   - Evidence:
     - `sendInvite()` in [Sources/Views/Family/FamilySettingsView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Family/FamilySettingsView.swift:380) contains comments for the real CloudKit share flow, then immediately dismisses success without doing it.
     - README claims secure family group invitations and real-time sync.
   - Impact: a core collaboration feature appears unimplemented or deceptive in current form.
   - Required fix: either implement the actual share/invite flow or remove the feature from release scope and metadata.

6. Several production code paths still rely on hard crashes or force-try patterns.
   - Evidence:
     - App startup fatal crash on model container failure: [Sources/App/MealMeldApp.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/App/MealMeldApp.swift:67)
     - Force-try regex parsing in cooking mode: [Sources/Views/Recipe/CookingModeView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Recipe/CookingModeView.swift:202)
     - Multiple preview/test scaffolds use `try!`, including [Sources/Views/MealPlanning/MealPlanningView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/MealPlanning/MealPlanningView.swift:379), [Sources/Views/Voting/VotingSessionView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Voting/VotingSessionView.swift:198), and [Sources/Views/Family/FamilySettingsView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/Family/FamilySettingsView.swift:401).
   - Impact: startup and parsing paths can terminate the app instead of failing gracefully.

### Should Fix Before App Review

7. Authentication data is persisted in `UserDefaults`, including Apple user ID and email.
   - Evidence: [Sources/Services/AuthenticationService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AuthenticationService.swift:97)
   - Impact: this is weaker storage than Keychain for account-linked identity. It may be acceptable for some apps, but it is a poor default for release.
   - Recommendation: store only what is necessary and prefer Keychain for persistent identity.

8. Logging and error handling are still partly debug-grade and may leak response payloads.
   - Evidence:
     - Raw OpenAI error body logged in [Sources/Services/AIService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AIService.swift:308)
     - Console `print` usage in auth, onboarding, voting, meal planning, shopping, and family settings, such as [Sources/Services/AuthenticationService.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Services/AuthenticationService.swift:50) and [Sources/Views/MealPlanning/MealPlanningView.swift](/Users/jasonchalky/Documents/GitHub/Familfeast/Sources/Views/MealPlanning/MealPlanningView.swift:259)
   - Impact: you have inconsistent release logging, weak user-facing recovery, and possible leakage of third-party response content into logs.

9. There is project drift risk from shipping with multiple app project files in the same repo.
   - Evidence:
     - `MealMeld.xcodeproj` uses bundle ID `com.mealmeld.app`
     - `FamilyFeast.xcodeproj` uses bundle ID `com.familyfeast.app`
   - Impact: build docs, signing, archive automation, and Fastlane can point at the wrong project or scheme.
   - Recommendation: pick one shipping project, archive the other, and make all release docs and automation reference exactly one path.

10. Fastlane/TestFlight automation is not present yet.
   - Evidence: no `fastlane/`, `Fastfile`, or `Appfile` was found in the repo.
   - Impact: “using Fastlane after” is not ready today; upload automation still needs to be created and verified.

## Recommended Order of Work

1. Remove client-side OpenAI key usage from the shipping app.
2. Decide whether `MealMeld.xcodeproj` is the only shipping project and clean up project/package drift.
3. Make the app target prove a clean build with a repeatable command.
4. Fix metadata/privacy/review answers before any external TestFlight distribution.
5. Either implement real CloudKit sharing/sync or reduce the scope of what the app claims to do.
6. Replace crash-prone `fatalError` and force-try behavior on production paths.
7. Add Fastlane only after the build and metadata story is stable.
