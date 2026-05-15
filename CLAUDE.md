# Fitrack — Claude context

This file is auto-loaded by Claude Code in this directory. It exists so any future session (including Claude integrations inside Xcode) starts with full project context.

## What this is

A personal, single-user iOS workout tracker built in SwiftUI + SwiftData for iOS 18 on iPhone 16. Not for distribution. Designed for hybrid training — 4–5 PPL lifts + 2–3 cardio (mostly Z2, occasional intervals) per week through summer.

The user (Shreyas) has never built an iOS app before. Default to concrete, step-by-step guidance on Xcode workflows when relevant. He works on a Mac, runs the simulator first, then deploys to his physical iPhone 16.

## Locked design decisions (do not re-litigate without asking)

- **Scope**: v1 = workouts only. Nutrition is v2; schema is already future-proofed.
- **No Apple Watch / HealthKit** in v1. Manual logging only.
- **Templates are required** to start a session. No freeform sessions in v1.
- **Storage**: SwiftData on-device only. Future migration target is Supabase (for laptop access). Models carry `id: UUID` + `updatedAt: Date` so the export JSON doubles as a migration payload.
- **Theme**: dark grey palette only (`#0E0E10` bg, `#D4D4D8` accent). **No purple, no AI-gradient looks.** Generous rounded corners (card=20, button=14, chip=10). Tokens live in `Fitrack/App/Theme/Theme.swift` — always reference, never hardcode hex.
- **Widgets**: deferred to v1.1.
- **Tests**: no XCTest suite in v1 — manual verification per README.

## Git etiquette

- Commit author MUST be `shreyas-challa <shreyas.challa3@gmail.com>`.
- **No `Co-Authored-By` trailers** on any commit. Do not add Claude/AI attribution.
- Do not open PRs. Push directly to `origin/main` after each coherent change.
- Push frequently — after each milestone or meaningful feature.

## Architecture

```
Fitrack/
├── App/              FitrackApp (entry), RootTabView (4 tabs), Theme tokens
├── Models/           SwiftData @Model types — single source of truth for schema
├── Persistence/      ModelContainer setup, SeedData (90-exercise library), ExportService
├── Features/
│   ├── Today/             Template list + start session
│   ├── Templates/         Lift + cardio template editors
│   ├── LiftSession/       In-gym lift logging UI (most-touched screen)
│   ├── CardioSession/     Cardio logging UI
│   ├── History/           Month heatmap + session list + detail
│   ├── Stats/             Streak, weekly volume, progression, PRs
│   ├── Settings/          About + JSON export
│   └── ExerciseLibrary/   Picker + add custom
├── Components/       Card, PrimaryButton, ScreenScaffold, RestTimer
├── Utils/            PRDetector, VolumeCalculator, StreakCalculator, SessionHelpers
└── Resources/        seed_exercises.json
```

### Models (relationships)

- `Exercise` — pre-seeded library (90 lifts) or `isCustom` user-added
- `WorkoutTemplate` → `[TemplateExercise]` (lift template)
- `CardioTemplate` — standalone
- `WorkoutSession` (`kind: .lift | .cardio`) → `[LoggedExercise]` → `[LoggedSet]`, OR `LoggedCardio`
- `PersonalRecord` — cached best weight per `(exercise, repBucket ∈ {1,3,5,8,10})`, updated by `PRDetector` on session finish

## When making changes

- **Don't hardcode colors, radii, or fonts** — use `Theme.Color.*`, `Theme.Radius.*`, `Theme.Font.*`.
- **No third-party dependencies.** Swift Charts and SwiftData are the only frameworks beyond SwiftUI.
- **Don't add comments unless WHY is non-obvious.** Code should be self-documenting.
- **Don't add backwards-compat shims** — this is a fresh, single-user app. If something is wrong, just fix it.
- **Don't add features the user didn't ask for.** v1 scope is locked. New ideas → ask first.

## Verification before claiming "done"

- For UI changes: build in Xcode (`⌘B`), then run in iPhone 16 simulator (`⌘R`) and exercise the actual flow. Watching code compile is not the same as feature verification.
- For data-model changes: SwiftData migrations are tricky — if you change a `@Model` field type or name after the app has run, the user must delete the simulator app to reset the store. Warn explicitly.
- For new dependencies on Bundle resources (JSON, images): verify they're added to the Fitrack target's Copy Bundle Resources phase.

## Setup state

- Repo: `/Users/subhashchalla/shreyas/fitrack`, remote at `github.com/shreyas-challa/fitrack`
- Xcode project (`Fitrack.xcodeproj`) is created by the user manually — Claude cannot generate it (pbxproj hand-crafting is fragile). See README for setup steps.
- All Swift sources already live under `Fitrack/` in the correct group structure for Xcode to ingest via "Add Files → Create groups".

## Known gotchas

- `extension WorkoutTemplate: Identifiable {}` etc. exist in some files because we need `Identifiable` for `.sheet(item:)` and `.fullScreenCover(item:)`. SwiftData `@Model` doesn't auto-conform to `Identifiable` (it provides `persistentModelID`, not `id`). The models all have `var id: UUID` which satisfies the protocol.
- The token that was visible in `git remote -v` is a leaked GitHub PAT and should be rotated. Re-auth via `gh auth login` or SSH.

## Future roadmap (not v1)

- Widgets (home + lock screen) — v1.1
- Supabase backend + laptop web dashboard — post-MVP. ExportService output is the migration payload.
- Nutrition tracking (meals, macros, creatine, calories) — v2. Add a parallel `Models/Nutrition/` folder; no changes needed to workout schema.
- Apple Watch / HealthKit — not planned.
