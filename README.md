# Cocktail Pantry iOS

Native iOS app that helps users track what they already own at home, discover cocktails they can make now, see what ingredients are missing for near-miss cocktails, and export shopping items to Apple Reminders.

## What the project does

- Capture owned ingredients from camera OCR, photo OCR, manual OCR text, or direct search.
- Store owned inventory locally.
- Show two recommendation modes:
  - `Can Make`
  - `Almost There` (missing ingredients)
- Build a shopping list from missing ingredients and send it to Apple Reminders.
- Optionally use OpenAI to improve OCR text-to-ingredient mapping.

## Features I am most proud of

- End-to-end pantry flow: capture -> confirm -> owned inventory.
- Ingredient normalization system (aliases + canonical IDs).
- Recommendation and missing-ingredient grouping UX.
- iOS-native integration with camera, photo library, OCR (`Vision`), and reminders (`EventKit`).
- Opt-in AI mapping path with API key stored in Keychain.

## How to run locally

1. Open [CocktailPantryFixed.xcodeproj](CocktailPantryFixed.xcodeproj) in Xcode.
2. Select scheme `CocktailPantry` and an iOS Simulator or physical iPhone.
3. In Signing & Capabilities, choose your Team and unique bundle identifier if needed.
4. Run the app.

Build command used during development:

```bash
xcodebuild -project CocktailPantryFixed.xcodeproj -scheme CocktailPantry -destination 'generic/platform=iOS Simulator' build
```

## How to use

1. Go to Pantry.
2. Add ingredients via:
   - Search (manual)
   - Camera/photo OCR
   - Manual OCR text
3. Open Discover to see `Can Make` and `Almost There` cocktails.
4. Open Shopping to add missing ingredients and export to Apple Reminders.

## Secrets and API handling

- OpenAI usage is optional and user-controlled.
- API key is entered in-app under Settings and stored in Keychain.
- No API keys are hard-coded in source files.

## Important files

- [App/CocktailPantryApp.swift](App/CocktailPantryApp.swift)
- [Views/PantryView.swift](Views/PantryView.swift)
- [Views/DiscoverView.swift](Views/DiscoverView.swift)
- [Views/ShoppingView.swift](Views/ShoppingView.swift)
- [Views/SettingsView.swift](Views/SettingsView.swift)
- [Services/RecommendationService.swift](Services/RecommendationService.swift)
- [Services/NormalizationService.swift](Services/NormalizationService.swift)
- [Services/OCRService.swift](Services/OCRService.swift)
- [Services/ReminderService.swift](Services/ReminderService.swift)
- [Services/AIService.swift](Services/AIService.swift)
- [Data/cocktails.seed.json](Data/cocktails.seed.json)
- [Data/ingredients.dictionary.json](Data/ingredients.dictionary.json)
