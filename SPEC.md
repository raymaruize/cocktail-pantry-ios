# Cocktail Pantry iOS — SPEC

## 0) Project Summary
Build a native iOS app (SwiftUI, no Expo) that helps users:
1. Identify what alcohol and mixers they already have (from photo + manual edit),
2. Discover cocktails they can make now,
3. See cocktails that are 1–2 ingredients away,
4. Export missing ingredients into Apple native Reminders as a shopping list.

This project is portfolio-focused and designed for fast MVP delivery with strong UI/UX and clear “manual coding” evidence.

---

## 1) Goals and Non-Goals

### Goals
- Native iOS app with polished UI (cards, tags/pills, icons, smooth transitions).
- Ingredient-aware cocktail recommendation engine.
- Distinguish similar but different ingredients (e.g., coconut milk vs coconut water).
- Show technique requirements (shake/stir/muddle/blend/build) and ice type.
- Add missing ingredients directly to Apple Reminders via EventKit.
- Photo recognition of bottle labels to seed ingredient inventory.

### Non-Goals (for MVP)
- Full autonomous barcode database integration.
- Multi-language OCR perfection.
- Real-time collaborative inventory sync across users.

---

## 2) User Stories
1. As a user, I can scan my liquor shelf to quickly add what I own.
2. As a user, I can manually edit inventory because OCR is imperfect.
3. As a user, I can see cocktails I can make right now.
4. As a user, I can see “almost possible” cocktails and what is missing.
5. As a user, I can export missing items to Apple Reminders with one tap.
6. As a user, I can understand technique requirements (shake/stir/muddle, ice type) from simple icon + tags.

---

## 3) Functional Requirements

### FR-1 Inventory Management
- Add/remove ingredients manually.
- Add ingredients from OCR suggestions.
- Track ingredient categories:
  - Base spirits (gin, vodka, rum, tequila, whiskey, brandy)
  - Liqueurs (triple sec, Campari, vermouth, etc.)
  - Mixers/non-alcoholic (milk, coconut milk, coconut water, tonic, soda, juices)
  - Fresh items (lime, mint, sugar)
  - Garnishes

### FR-2 Ingredient Normalization (Critical)
- Normalize synonyms while preserving distinct items:
  - Example normalize: “lime juice”, “fresh lime juice” -> `lime_juice`
  - Keep separate: `coconut_milk` ≠ `coconut_water`
- Maintain alias dictionary and strict canonical IDs.

### FR-3 Cocktail Catalog
Each cocktail record must include:
- Name
- Ingredients list (canonical IDs + amounts)
- Method (shake/stir/muddle/blend/build)
- Ice type (none/cubed/crushed/large cube)
- Glassware (optional in MVP, preferred)
- Garnish (optional in MVP, preferred)
- Flavor tags (citrusy/sweet/bitter/creamy/strong)
- Difficulty (easy/medium/hard)

### FR-4 Recommendation Engine
- “Can Make Now”: all required ingredients available.
- “Almost There”: missing <= 2 ingredients.
- Ranking for “Almost There”:
  1. Fewer missing ingredients first,
  2. Higher popularity score,
  3. Lower optional-complexity.

### FR-5 Shopping Suggestion
- Aggregate missing ingredients from selected “Almost There” cocktails.
- Optional optimizer: choose top K ingredients that unlock most cocktails.
- Export list to Apple Reminders in a dedicated list, e.g. `Cocktail Shopping`.

### FR-6 Apple Reminders Integration
- Request reminders permission at first export.
- Create/find list named `Cocktail Shopping`.
- Write one reminder per ingredient.
- Optional notes format: `Needed for: Margarita, Daiquiri`.

### FR-7 Photo Recognition
- Input: shelf/bottle photo from camera or gallery.
- OCR: detect text from labels.
- Candidate mapping from recognized text -> known ingredients.
- User confirmation screen before adding.

---

## 4) UI/UX Specification (High Priority)

### Design Language
- Clean, modern, high-contrast cards.
- Pills/tags for flavor, method, ice, missing-count.
- SF Symbols icons for fast scanning.
- Subtle blur/gradient surfaces for premium look.
- Haptics on key actions (add ingredient, export reminders).

### Main Tabs
1. **Pantry**
   - Search bar + category filters
   - Ingredient chips with status
   - Add button (manual + photo scan)

2. **Discover**
   - Segments: `Can Make` / `Almost There`
   - Cocktail cards with hero icon, method tag, ice tag, flavor pills
   - Missing ingredients shown as red outlined pills

3. **Shopping**
   - Consolidated missing list
   - “Unlock count” badges (e.g., `+4 cocktails`)
   - CTA: `Send to Apple Reminders`

4. **Details (sheet/push)**
   - Ingredient list with checkmarks vs missing
   - Step-by-step method
   - Technique + ice visual tags

### Visual Components
- **Pill Tag**:
  - Rounded capsule, small icon + label
  - Variants: neutral / success / warning / missing
- **Cocktail Card**:
  - Name + small image/illustration placeholder
  - Rows of pills: method, ice, flavor
  - Footer: `Can Make` or `Missing 1`

### Interaction Notes
- Keep flows 1–2 taps deep.
- Always let user override OCR mistakes quickly.
- Prioritize readability over dense text.

---

## 5) Data Model (MVP)

```text
Ingredient {
  id: String            // canonical id, e.g. coconut_milk
  displayName: String   // "Coconut Milk"
  category: IngredientCategory
  aliases: [String]
}

PantryItem {
  ingredientId: String
  isAvailable: Bool
  quantityHint: String? // optional MVP+
}

Cocktail {
  id: String
  name: String
  ingredients: [CocktailIngredient]
  method: Technique      // shake/stir/muddle/blend/build
  ice: IceType           // none/cubed/crushed/large_cube
  glassware: String?
  garnish: [String]
  flavorTags: [FlavorTag]
  popularityScore: Int
}

CocktailIngredient {
  ingredientId: String
  amount: String?        // "2 oz"
  optional: Bool
}
```

---

## 6) Source of Cocktail Menu Data

### Recommended strategy
- Start with local JSON dataset (50–120 classics) curated by us for reliability.
- Add fields we need but public APIs often lack (ice type, technique detail, tags).

### Candidate sources (for bootstrapping only)
- TheCocktailDB (good starter metadata; validate and enrich manually)
- IBA official cocktail list (canonical classics; manually structure)

### Important
- Build a `cocktails.seed.json` in project bundle.
- Build `ingredients.dictionary.json` for alias/normalization rules.

---

## 7) Core Algorithms (Manual/Deep-Modified Section)

### A) Normalization Engine
- Lowercase, trim, punctuation removal.
- Alias dictionary lookup.
- Fuzzy fallback only if confidence threshold met; otherwise ask user confirm.

### B) Match Engine
- For each cocktail, compare required ingredient IDs with pantry set.
- Output:
  - `canMake: Bool`
  - `missing: [ingredientId]`

### C) Near-Miss Ranker
Score example:

`score = w1*(2 - missingCount) + w2*popularity + w3*simplicity`

- Higher score first.
- Missing count hard cap for “Almost There”: <= 2.

### D) Shopping Optimizer (MVP+)
- Greedy set-cover style:
  - Pick ingredient that unlocks the maximum number of currently-locked cocktails.
  - Repeat until K picks.

---

## 8) Tech Stack (Native iOS)
- Swift 5+
- SwiftUI
- Vision (OCR)
- EventKit (Reminders)
- Optional: CoreData/SwiftData for pantry persistence

Architecture suggestion:
- `Views/`
- `ViewModels/`
- `Models/`
- `Services/` (`OCRService`, `ReminderService`, `RecommendationService`)
- `Data/` (seed JSON)

---

## 9) Apple Reminders Integration Plan
1. Create `ReminderService`.
2. Request permission for reminders.
3. Find or create calendar/list: `Cocktail Shopping`.
4. Upsert reminders from missing ingredients.
5. Handle denied permission with clear fallback message.

---

## OpenAI / ChatGPT Integration

Purpose:
- Provide an optional AI-assisted pathway to: (a) identify ambiguous bottle/label text from OCR, (b) map free-form recognized text to canonical `ingredient.id` values, and (c) fetch or enrich cocktail metadata (technique, ice, tags) from internet sources when our local seed lacks details.

Use cases:
- Given OCR text (or a short user description), propose a ranked list of candidate `ingredient.id`s with confidence scores and justification.
- Given a partial ingredient list or cocktail name, query the web (or use the model's knowledge) to return a structured cocktail record matching our `Cocktail` schema.
- Suggest likely substitutions and note uncertainty for user confirmation.

Architecture & implementation notes:
- Add an `AIService` (optional) that encapsulates calls to OpenAI's APIs (Chat Completions / Functions or Responses API).
- Flow examples:
  1. Run OCR -> extract text snippets.
  2. Send cleaned snippets to `AIService` with a short prompt + schema request (JSON output) asking for candidate ingredient IDs and confidence.
  3. Validate AI output against the local `ingredients.dictionary.json` (aliases/IDs). If unmatched, present to user for confirmation before adding to pantry.
 4. For cocktail enrichment: request structured cocktail data (name, ingredients with canonical IDs, method, ice, tags) and merge with local `cocktails.seed.json` after human review.

Prompting & schema guidance:
- Use explicit system prompts and a strict JSON schema to reduce hallucination. Example response shape:
  {
    "candidates": [
      {"text":"" , "ingredientId":"", "confidence":0.0, "reason":""}
    ],
    "source":"web|model|database",
    "notes":""
  }
- Prefer function-calling / JSON-schema validation features where available so the model returns parseable structured data.

Privacy, keys & rate-limiting:
- Require an explicit user opt-in before sending any data to OpenAI. Do not auto-enable.
- Avoid sending raw images; send OCR-extracted text snippets only. If image content must be sent, clearly disclose and obtain consent.
- Store API keys in Keychain, not in source. Support using a developer/local key for testing and a user-provided key for production use.
- Cache AI responses (local ephemeral cache) and enforce request rate-limits to avoid unexpected costs.

Failure modes & fallbacks:
- If the model returns low-confidence or ambiguous matches, fall back to the conservative path: show suggestions but require manual confirmation.
- Never auto-add an ingredient or overwrite canonical IDs without user approval.

Acceptance criteria for enabling AI integration (optional MVP):
- User can opt-in to AI assistance in settings.
- OCR -> AI candidate mapping presents at least 3 ranked candidates with confidence and an action to confirm.
- Cocktail enrichment returns structured JSON that can be previewed and accepted by the user before merging.

Testing considerations:
- Unit-test prompt/response parsing logic using recorded (mock) responses.
- Integration tests should mock OpenAI responses and verify that only allowed fields are merged and that no raw image payloads are sent without consent.


## 10) Photo Recognition Plan
1. Capture/select image.
2. Run OCR text recognition.
3. Match text snippets against ingredient aliases.
4. Present confidence-ranked suggestions.
5. User confirms selected items before adding.

---

## 11) Edge Cases
- Coconut milk vs coconut water must remain separate IDs.
- Milk vs cream vs coconut cream are distinct.
- Optional garnish should not block “Can Make”.
- OCR low confidence should never auto-commit.
- Duplicate reminder entries should be prevented.

---

## 12) MVP Scope (Checkpoint-Ready)
By checkpoint, we must have:
- Native iOS app shell with Pantry + Discover + Shopping screens.
- Local cocktail dataset loaded.
- Matching logic for can-make and missing<=2.
- Apple Reminders export working end-to-end.
- Basic OCR -> suggestion -> confirm flow.

---

## 13) Stretch Goals
- Beautiful cocktail image assets.
- Smart substitutions (lemon vs lime in some recipes with warning badge).
- Pantry quantity tracking and depletion.
- Seasonal recommendation mode.

---

## 14) Testing Plan
- Unit tests:
  - normalization mapping
  - match results
  - near-miss ranking
- Integration tests:
  - reminders write path
  - OCR suggestion flow with sample images
- Manual QA:
  - denied permissions
  - empty pantry
  - edge ingredient confusion

---

## 15) Deliverables Mapping (for course)
- `README.md`: setup, architecture, known limitations.
- `PROMPT_LOG.md`: important prompts + AI workflow.
- `REFLECTION.md`: your own writing only.
- Demo video: show real iOS device + reminders export.
- Oral exam prep: be ready to explain normalization + ranking + reminders integration.

---

## 16) Build Order (Practical)
1. Models + seed JSON
2. RecommendationService
3. Pantry UI
4. Discover UI (cards/pills/icons)
5. Shopping UI + ReminderService
6. OCR flow
7. Polish animations/haptics

---

## 17) Success Criteria
- User can identify inventory, discover doable cocktails, and export shopping list in under 60 seconds.
- UI is visually clean and easy to scan.
- Distinct ingredient handling is correct for tricky pairs.
- Core logic is clearly authored/modified by student and explainable in oral exam.
