# App Store Connect Submission

## App

bundle_id: com.mealmeld.app
name: MealMeld
subtitle: Family Meal Planning
platform: ios
version: 1.0.0
build: 1
category_primary: Food & Drink
category_secondary: Lifestyle
content_rights: no
copyright: 2026 Jason Chalky

## Age Rating

violence: none
cartoon_violence: none
mature_suggestive: none
nudity: none
sexual_content: none
horror: none
medical: none
alcohol_tobacco: none
gambling: no
unrestricted_web: no

## Localizations

### English (en-US)

description: |
  MealMeld turns "What's for dinner?" from a solo chore into a family vote. Stop arguing about meals and start agreeing on them.

  Every family member gets a voice. Swipe right on meals you love, left on ones you don't, and let the Borda Count consensus algorithm pick dishes that make everyone happy -- no more one person deciding for the whole family.

  Key Features:

  - Democratic Voting: Tinder-style swipe interface lets every family member weigh in. The consensus algorithm finds meals everyone can agree on, avoiding polarizing choices.

  - Smart Shopping Lists: Automatically generated from your finalized meal plans, organized by grocery aisle. Track your budget and check items off as you shop.

  - Recipe Scaling & Cooking Mode: Adjust servings up or down and follow step-by-step cooking instructions with built-in countdown timers. View nutrition info including calories, protein, carbs, fat, fiber, and sodium.

  - Dietary Profiles: Set per-member dietary restrictions (vegetarian, vegan, gluten-free, keto) and allergen alerts (peanuts, tree nuts, shellfish, dairy). Get automatic conflict warnings when a meal plan doesn't work for someone.

  - Weekly Meal Calendar: Schedule meals across the week with session management. The app considers prep time and family schedules to keep things realistic.

  - Budget Management: Estimate costs per recipe and per meal plan, track actual spending versus estimates, and get alerts when you're approaching your limit.

  MealMeld is privacy-first. All data is stored locally on your device. No accounts to create, no tracking, no ads. Sign in with Apple is optional and only stores an Apple-issued ID and display name on-device.

keywords: meal planning,family,recipes,voting,shopping list,dinner,cooking,weekly meals,diet,budget
whats_new: Initial release.
promo_text: Turn "What's for dinner?" into a family vote. Plan meals together, shop smarter, and cook with confidence.
support_url: https://chalkyjason.github.io/MyWebsite/projects/mealmeld/support
marketing_url: https://chalkyjason.github.io/MyWebsite/projects/mealmeld/

## Screenshots

### 6.9-inch (iPhone 16 Pro Max)

- docs/screenshots/appstore/screenshot_01.png  # Onboarding welcome screen
- docs/screenshots/appstore/screenshot_02.png  # Dashboard with quick actions and stats
- docs/screenshots/appstore/screenshot_03.png  # Recipe browser with search and filters
- docs/screenshots/appstore/screenshot_04.png  # Shopping list management
- docs/screenshots/appstore/screenshot_05.png  # Family settings and member management

# NOTE: Screenshots captured automatically from simulator. No UI screenshot tests exist.
# Recommend creating XCUITest screenshot tests for more polished captures with sample data.

## Review Contact

first_name: Jason
last_name: chalkyjason
phone: +1 (234) 228-5103
email: chalkyjason@gmail.com
notes: |
  MealMeld is a local-first meal planning app for families. To test the core flow:
  1. Launch the app. Sign in with Apple is offered but optional -- you can skip it and use the app fully.
  2. Complete onboarding (name your family group).
  3. Add a few recipes manually from the Recipes tab.
  4. Create a voting session from the Meal Planning tab.
  5. Swipe to vote on recipes.
  6. View the consensus results and schedule meals.
  7. Generate a shopping list from a finalized meal plan.

  All data is stored locally on-device with SwiftData. There is no server, no third-party account, and no analytics SDK.

## Pricing

price: Free
availability: all
pre_order: false

## Privacy

privacy_url: https://chalkyjason.github.io/MyWebsite/projects/mealmeld/privacy-policy
data_collected: User ID

## Compliance

uses_encryption: no
exempt: yes
france_declaration: no
ern_number:

## Review Questions

- question: Does your app use the Advertising Identifier (IDFA)?
  answer: no

- question: Does this app contain, display, or access third-party content?
  answer: no
