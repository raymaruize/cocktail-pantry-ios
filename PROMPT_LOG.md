# PROMPT_LOG — Cocktail Pantry iOS

## AI tools used
- GitHub Copilot (VS Code agent)
- GPT-5.3-Codex
- Xcode build tooling (`xcodebuild`) for compile verification

## Development log (chronological)

> NOTE: Prompts below are representative, quoted prompts used during development and debugging.

### 1) Scope + spec setup
- Prompt: "Continue from `HANDOFF.md` and `SPEC.md`. Build the iOS app and include OpenAI integration."
- Output: app architecture, feature plan, data models, services, and implementation sequence.

### 2) Initial app implementation
- Prompt: "Start to build the app now. Create everything for me."
- Output: SwiftUI app shell, tabs, models, services, seed JSON, and recommendation pipeline.

### 3) UI/full-screen fixes
- Prompt: "Redo UI/UX and use full screen. There are black spaces."
- Output: full-screen layout and launch/config updates, camera picker presentation fixes.

### 4) OCR/AI flow fixes
- Prompt: "It is not going anywhere, check why OCR analyze is stuck."
- Output: loading-state fixes, timeout/error handling, improved logs, and user-facing status messaging.

### 5) Manual ingredient entry
- Prompt: "Be able to manually input liquor names so I don’t rely on OCR."
- Output: search-based manual add flow in Pantry.

### 6) AI debug + dictionary mapping
- Prompt: "OpenAI is active but I still get no suggestions."
- Output: dictionary/resource loading fixes and ID normalization/fuzzy matching improvements.

### 7) Recommendation display refinements
- Prompt: "For can-make list ingredients too; for shopping flip to ingredient-first cards."
- Output: Discover now shows ingredient lists for makeable cocktails; Shopping is ingredient-first.

### 8) OCR should add owned items directly
- Prompt: "Use photos/manual input to add what I have right now as owned."
- Output: OCR path now supports suggest-and-add + add-all behavior.

### 9) Wine recognition + overlap fixes
- Prompt: "Sometimes it overlaps; red wine photos should give better suggestions."
- Output: OCR sheet layout stabilization, wine aliases/canonical IDs, seed data updates.

## Manual coding / substantial modifications done by me
- Reviewed and iterated architecture and file structure.
- Chose and refined app behavior, especially pantry ownership flow.
- Directed data model expansions (wine support, aliases).
- Verified build repeatedly and adjusted based on runtime behavior.
- Reviewed recommendation UI behavior and requested multiple iterations.

## Verification work
- Repeated compile checks with:
  - `xcodebuild -project CocktailPantryFixed.xcodeproj -scheme CocktailPantry -destination 'generic/platform=iOS Simulator' build`
- Runtime checks in simulator + phone-style flows:
  - Pantry OCR/manual add
  - Discover can-make/almost-there
  - Shopping ingredient-first list
  - OpenAI mapping path

## Approximate effort evidence
- Multi-day iteration across architecture, UI, OCR, AI integration, and polish.
- Many incremental code changes with repeated compile verification.
