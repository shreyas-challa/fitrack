# Fitrack

A personal iOS workout tracker for hybrid training (PPL lifts + Z2/interval cardio). Single-user, no distribution.

## Status

v1 source code is complete. Awaiting Xcode project creation (see below).

## Stack

- SwiftUI + SwiftData (iOS 18, iPhone 16)
- Swift Charts for stats
- No third-party dependencies

## Features

- **Today**: pick a lift or cardio template, tap to start a session
- **Lift session**: per-set weight/reps logging with last-session inline hint, optional RPE, auto-starting rest timer, finish/cancel confirmation
- **Cardio session**: live elapsed timer, duration/distance/HR/RPE/notes, interval-spec field for intervals templates
- **Templates**: create/edit/delete lift templates (with per-exercise sets/rep-range/rest) and cardio templates (type, intensity, duration, distance)
- **Exercise library**: 90 pre-seeded lifts tagged by muscle group + equipment, plus custom exercise add
- **History**: month calendar heatmap (rest / lift / cardio / both), recent sessions list, session detail with full set table
- **Stats**: current/longest streak, weekly volume by muscle group (Swift Charts bar), weekly cardio minutes, per-exercise progression line chart (Epley e1RM), automatic PR detection at 1/3/5/8/10-rep buckets
- **Export**: one-tap JSON export of all data (templates, sessions, PRs) — backup-ready and migration-ready for a future backend

## Project layout

```
Fitrack/
├── App/              # Entry point, root tab view, theme tokens
├── Models/           # SwiftData @Model types
├── Persistence/      # ModelContainer, seed data, export service
├── Features/         # Today / Templates / LiftSession / CardioSession / History / Stats / Settings / ExerciseLibrary
├── Components/       # Card, PrimaryButton, RestTimer, ScreenScaffold
├── Utils/            # PRDetector, VolumeCalculator, StreakCalculator, SessionHelpers
└── Resources/        # seed_exercises.json (90 lifts)
```

## Xcode setup (first time only)

1. Open Xcode → **File → New → Project → iOS → App**.
   - Product name: `Fitrack`
   - Interface: SwiftUI
   - Storage: SwiftData
   - Language: Swift
   - Minimum deployment: iOS 18.0
   - Save the project **inside this repo** (`/Users/subhashchalla/shreyas/fitrack`).
2. Xcode auto-generates `FitrackApp.swift` and `ContentView.swift` — **delete both** (we already have ours under `Fitrack/`).
3. In Xcode's Project Navigator, right-click the `Fitrack` group → **Add Files to "Fitrack"…**, select the existing `Fitrack/` folder, choose **"Create groups"** (not folder references) and ensure the **Fitrack target** is checked.
4. Select `Fitrack/Resources/seed_exercises.json` in the navigator → File Inspector (right panel) → Target Membership → ensure **Fitrack** is checked. This puts it in Copy Bundle Resources.
5. **Project settings → Signing & Capabilities** → pick your personal Apple ID team.
6. Build & run on **iPhone 16 simulator** (`⌘R`).

If everything compiles, you should see the dark-themed Today tab with a "No templates yet" card.

## Running on your iPhone

1. Plug in iPhone 16 via USB. Trust the Mac when prompted.
2. In Xcode: **top toolbar → device dropdown → your iPhone**.
3. First run prompts you to trust the developer profile on the phone: **Settings → General → VPN & Device Management** → tap your Apple ID → Trust.
4. Hit Run.
5. Subsequent runs can be wireless once the phone shows up under **Window → Devices and Simulators**.

Free Apple ID: app re-signs every 7 days (re-run from Xcode). Paid Apple Developer Program ($99/yr): 1-year signing, no re-sign hassle.

## Test plan (manual verification)

After Xcode project setup, work through these on simulator:

1. App launches in dark mode, no purple anywhere — only dark greys + a cool light grey accent.
2. **Templates**: tap + → New Lift Template → name "Push A" → add Bench, OHP, Lateral Raise → set targets → Save. Repeat for cardio template "Z2 Bike 45".
3. **Lift session**: tap "Push A" → log 3 working sets per exercise → mark each set complete (rest timer auto-starts) → Finish.
4. **Last-session hint**: start "Push A" again → previous numbers show in the LAST column.
5. **PR detection**: log a set heavier than last time at same rep bucket → after Finish, check Stats → PRs section shows it.
6. **Cardio session**: tap "Z2 Bike 45" → adjust duration if needed, set RPE to 5, add a note → Finish.
7. **History**: today shows colored dots in the calendar. Tap → session list. Tap session → detail.
8. **Stats**: streak shows 1+, weekly volume chart shows muscle groups you trained, progression chart populates once you have 2+ sessions on the same exercise.
9. **Export**: Settings → Export to JSON → share sheet → save to Files. Open in a text editor — you should see the full payload with schemaVersion=1.

## Future (post-v1)

- Widgets (home / lock screen)
- iCloud / CloudKit sync, OR Supabase backend + web dashboard for laptop access
- Nutrition tracking (meals, macros, calories) — schema is already future-proofed
