# Fitrack

A personal iOS workout tracker for hybrid training. Single-user, no distribution.

## Stack

- SwiftUI + SwiftData (iOS 18, iPhone 16)
- Swift Charts for stats
- No third-party dependencies

## Project layout

```
Fitrack/
├── App/              # Entry point, root tab view, theme tokens
├── Models/           # SwiftData @Model types (single source of truth)
├── Persistence/      # ModelContainer + seed data
├── Features/         # Today / Templates / LiftSession / CardioSession / History / Stats / Settings / ExerciseLibrary
├── Components/       # Reusable: Card, PrimaryButton, ScreenScaffold...
├── Utils/            # PRDetector, VolumeCalculator, StreakCalculator
└── Resources/        # seed_exercises.json (~90 lifts)
```

## Xcode setup (one-time)

1. Install Xcode from the Mac App Store (~10 GB).
2. Open Xcode → **File → New → Project → iOS → App**.
   - Product name: `Fitrack`
   - Interface: SwiftUI
   - Storage: SwiftData
   - Language: Swift
   - Minimum deployment: iOS 18.0
   - Save the project **inside this repo** (`/Users/subhashchalla/shreyas/fitrack`).
3. Delete the auto-generated `FitrackApp.swift` and `ContentView.swift` Xcode created — we already have ours under `Fitrack/`.
4. In Xcode's Project Navigator, right-click the `Fitrack` group → **Add Files to "Fitrack"…** and add the existing `Fitrack/` folder (choose "Create groups", not folder references).
5. Add `Fitrack/Resources/seed_exercises.json` to **Copy Bundle Resources** under the Fitrack target → Build Phases.
6. Build & run on **iPhone 16 simulator**.

## Running on your iPhone

1. Plug in iPhone 16 via USB.
2. In Xcode: **Signing & Capabilities** → select your personal Apple ID team. (Free account = re-sign every 7 days; $99/yr Developer Program = 1 year.)
3. Trust the developer profile on iPhone: Settings → General → VPN & Device Management.
4. Hit **Run**. Subsequent runs can be wireless once the phone shows up in **Window → Devices**.

## Build milestones

- **M0 + M1** — Project skeleton, theme, root tab view, SwiftData models, seed library
- **M2** — Template CRUD (lift + cardio)
- **M3** — Lift session logging (the core in-gym screen)
- **M4** — Cardio session logging
- **M5** — History calendar + session detail
- **M6** — Stats (progression, volume, PRs, streak)
- **M7** — Polish + JSON export + device install

See [plan](https://github.com/shreyas-challa/fitrack) for the locked design decisions.
