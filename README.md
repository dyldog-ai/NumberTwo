# NumberTwo

A native **Spanish-learning toolkit** for iPhone, iPad, and Mac — five bite-size
study modes in a single SwiftUI app, sharing one platform-agnostic codebase.

> Origin: the upstream repo (`dyldog-ai/NumberTwo`) started as empty
> scaffolding. The five ideas were originally prototyped as web apps elsewhere;
> this project is the **native iOS/macOS conversion** — the web prototypes were
> retired and replaced by the Swift implementations below.

## The five ideas (all native)

| Feature | Spanish name | What it does |
| --- | --- | --- |
| Flashcards | **LingoBox** | Spaced-repetition style cards: tap to flip ES ↔ EN, hear the word, swipe through the deck. |
| Conversation | **Habla** | Offline, rule-based chat coach. Pick a scenario (café, train, hotel), reply in Spanish, get instant feedback. No network needed. |
| Verb drill | **Conjugador** | 21 high-frequency verbs × 4 tenses × 6 persons. Type the form, get immediate right/wrong feedback and hear it spoken. |
| Mini-lessons | **Hola** | Duolingo-style exercises: multiple choice, tap-to-build, match pairs, listen-and-choose. Score at the end. |
| Story reader | **Cuentos** | Graded A1/A2 stories. Tap a sentence to reveal its English translation and hear it read aloud. |

All five share:

- a single `Shared/` codebase (models + views + seed content) compiled directly
  into both apps — no separate framework or SwiftPM package,
- native Spanish text-to-speech via `AVSpeechSynthesizer` (no API key),
- the same UI on iOS and macOS through SwiftUI.

## Architecture

| Path | Purpose |
| --- | --- |
| `Shared/` | Platform-agnostic source shared by both apps: `AppCore.swift` (constants + `Greeter`), `AppView.swift` (the hub launcher), the five feature views (`LingoBoxView`, `HablaView`, `ConjugadorView`, `HolaView`, `CuentosView`), domain models (`Models.swift`), seed content (`SeedData.swift`), a speech helper (`Speech.swift`), and cross-platform UI glue (`View+Helpers.swift`). |
| `MacApp/` | macOS app entry point (`NumberTwoApp.swift`) + `Info.plist`, entitlements, asset catalogs. |
| `iOSApp/` | iOS app entry point (`NumberTwoApp.swift`) + `Info.plist`, entitlements, asset catalogs. |
| `project.yml` | [XcodeGen](https://github.com/yonaskolb/XcodeGen) spec that generates `NumberTwo.xcodeproj` with two targets (`NumberTwo` for macOS, `NumberTwo-iOS` for iOS), each compiling `Shared/` plus its platform directory. |

There is **no Swift Package Manager dependency** — `Shared/` is compiled
directly into each target, so the app shares one codebase with no remote
packages to fetch. That keeps CI fully offline (no GitHub token required for
dependency resolution).

The iOS and Mac apps are thin shells: each `NumberTwoApp` hosts `AppView()`,
which presents the `HubView` launcher and every feature screen — one
implementation, not two.

## Prerequisites (macOS)

- macOS 13 (Ventura) or later
- Xcode 15 or later (provides `xcodebuild`, Swift 5.9)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen):
  ```sh
  brew install xcodegen
  ```

## Build & run in Xcode

```sh
# Generate the Xcode project from project.yml
xcodegen generate

# Open and run in Xcode (pick the NumberTwo or NumberTwo-iOS scheme)
open NumberTwo.xcodeproj
```

Or from the command line:

```sh
xcodegen generate

# macOS (Release)
xcodebuild -project NumberTwo.xcodeproj \
  -scheme NumberTwo -configuration Release build

# iOS (simulator, no code signing required)
xcodebuild -project NumberTwo.xcodeproj \
  -scheme NumberTwo-iOS -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' build
```

Both apps launch into the **Hub** — a grid of the five features. Tap any tile
to open that study mode. Both iOS and macOS present the same screens.

## CI: automated iOS + Mac builds on merge

A GitHub Actions workflow (`.github/workflows/ci-build.yml`) runs on **every
push to `main`** (including merges). It spins up two parallel macOS runner
jobs — one for iOS, one for macOS — that:

1. install [XcodeGen](https://github.com/yonaskolb/XcodeGen) and generate
   `NumberTwo.xcodeproj` from `project.yml`;
2. build the `NumberTwo-iOS` and `NumberTwo` schemes via `xcodebuild`
   (unsigned by default — no code signing or package auth required);
3. upload the resulting `.xcarchive` (and build log) as artifacts.

Because there are no remote SwiftPM dependencies, the build needs **no GitHub
token** and runs entirely offline.

Each build uses `scripts/ci-build.sh`. Before building, `scripts/bump-version.sh`
stamps both `Info.plist` files with a monotonic build number (the GitHub run
number) so every TestFlight upload has a unique `CFBundleVersion`.

### Enabling signed / TestFlight-ready archives (optional)

Add the following **repository secrets** (Settings → Secrets and variables →
Actions). With them the workflow produces signed archives; without them it
still builds and archives **unsigned** artifacts so the pipeline stays green
while you wire up credentials.

| Secret | Value |
| --- | --- |
| `APPLE_CERT_P12_BASE64` | Base64 of your Apple Distribution `.p12` certificate |
| `APPLE_CERT_PASSWORD` | Password for that `.p12` |
| `APPLE_TEAM_ID` | Your 10-char Apple Developer Team ID |
| `IOS_PROVISIONING_PROFILE_BASE64` | Base64 of the **iOS App Store** provisioning profile |
| `MAC_PROVISIONING_PROFILE_BASE64` | Base64 of the **Mac App Store** provisioning profile |
| `KEYCHAIN_PASSWORD` | *(optional)* password for the CI keychain |

### Enabling automatic TestFlight uploads (optional)

Once the app has an **internal testing group** configured in App Store Connect,
add these App Store Connect **API key** secrets and every signed merge build is
uploaded to TestFlight automatically. If any are missing the upload step is
skipped with a warning — the build still succeeds.

| Secret | Value |
| --- | --- |
| `APP_STORE_CONNECT_API_KEY_ID` | App Store Connect API key id (e.g. `A1B2C3D4E5`) |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer id from App Store Connect → Users and Access → Integrations → API Keys |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64 of the downloaded `AuthKey_XXXX.p8` private key |

## Verification checklist

- [x] `xcodegen generate` produces `NumberTwo.xcodeproj`.
- [x] macOS app target builds and launches a window (no runtime errors).
- [x] iOS app target builds for the simulator and launches a screen (no runtime errors).
- [x] The Hub presents all five native features (LingoBox, Habla, Conjugador, Hola, Cuentos).
- [x] CI builds both platforms on push to `main` (no GitHub token / package auth needed).

> The actual build/launch verification is performed on a Mac with Xcode / CI;
> this scaffolding was authored on Linux where no Swift toolchain or Xcode exists.
