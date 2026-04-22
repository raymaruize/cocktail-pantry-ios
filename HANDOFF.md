# HANDOFF — Cocktail Pantry iOS

Last updated: 2026-04-15

## 1) Project Snapshot
- Project name: **Cocktail Pantry iOS**
- Location: `/Users/ruizema/clawd/cocktail-pantry-ios`
- Platform: **Native iOS (SwiftUI)**
- Key integration: **Apple Reminders** via `EventKit`
- Core user value: Scan/record what alcohol + mixers user has, then recommend cocktails:
  - can make now
  - almost make (missing 1–2 items)
  - export missing items into Apple Reminders shopping list

## 2) Why this project fits the course
Satisfies multiple requirement dimensions:
- Phone app (native iOS)
- Frontend logic + service integration
- Third-party/ML style module via OCR (Vision)
- Potential data persistence layer (SwiftData/CoreData)

Oral-exam-ready “manual/deep-modified” areas:
1. Ingredient normalization engine
2. Near-miss ranking algorithm
3. Shopping optimizer (unlock-most-cocktails with least items)

## 3) Requirements already captured
Primary specification exists in:
- `SPEC.md`

Key requested product details already included:
- Distinguish similar items (`coconut_milk` vs `coconut_water`, milk vs cream, etc.)
- Show method tags (`shake`, `stir`, `muddle`, `blend`, `build`)
- Show ice type (`cubed`, `crushed`, `large cube`, `none`)
- Use icon + tag/pill UI style
- Photo-based bottle recognition + user confirmation
- Export missing ingredients to Apple Reminders

## 4) Proposed Architecture
- `Models/`
  - `Ingredient`, `Cocktail`, `CocktailIngredient`, enums for method/ice/tags
- `Services/`
  - `NormalizationService`
  - `RecommendationService`
  - `ReminderService` (`EventKit`)
  - `OCRService` (`Vision`)
- `ViewModels/`
  - `PantryViewModel`, `DiscoverViewModel`, `ShoppingViewModel`
- `Views/`
  - Pantry / Discover / Shopping / CocktailDetail
- `Data/`
  - `cocktails.seed.json`
  - `ingredients.dictionary.json`

## 5) Data source plan (cocktail menu)
- Start with curated local JSON (50–120 classic cocktails)
- Bootstrap from public references (e.g., TheCocktailDB / IBA), then normalize + enrich manually
- Keep canonical ingredient IDs strict to avoid semantic collisions

## 6) UI/UX direction
- Clean modern cards + pills + SF Symbols icons
- Fast scanability and low tap depth
- Sections:
  - Pantry
  - Discover (`Can Make` / `Almost There`)
  - Shopping (with `Send to Apple Reminders` CTA)
- Nice-to-have polish: haptics, subtle gradients, micro-interactions

## 7) MVP Definition (checkpoint-safe)
Must work end-to-end:
1. Manual pantry CRUD
2. Cocktail matching (can make + missing <= 2)
3. Shopping list aggregation
4. Export missing items to Apple Reminders
5. Basic OCR suggestion flow with manual confirmation

## 8) Immediate next steps (execution order)
1. Initialize Xcode project (SwiftUI app)
2. Add model layer + sample seed JSON
3. Implement `NormalizationService`
4. Implement `RecommendationService` + tests
5. Build Pantry and Discover screens
6. Implement `ReminderService` and export flow
7. Add OCR flow (`Vision`) and confirmation screen
8. Final UI polish + demo script prep

## 9) Acceptance Criteria for first demo
- User adds pantry items (manual and/or OCR suggestions)
- App shows at least:
  - 5+ “Can Make” or “Almost There” results from seed data
- User exports missing ingredients to Apple Reminders list `Cocktail Shopping`
- Ingredient distinctions are correct for tricky pairs

## 10) Risks and mitigations
- OCR inaccuracy -> require user confirmation before commit
- Reminder permission denied -> fallback guidance UI
- Dataset inconsistency -> canonical IDs + validation script/test
- Scope creep -> lock MVP first, polish second

## 11) Files currently present
- `SPEC.md`
- `HANDOFF.md`

## 12) Recommended message to resume in a new chat/workspace
> Continue from `cocktail-pantry-ios/HANDOFF.md` and `cocktail-pantry-ios/SPEC.md`. Start by scaffolding the SwiftUI project structure, data models, and seed JSON, then implement normalization + recommendation engine first.
