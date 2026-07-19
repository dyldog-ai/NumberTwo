# NumberTwo

A cool-looking **random number generator** for macOS and iOS, built with SwiftUI and XcodeGen.

## Features

- **Six modes:** Integer, Decimal, Dice, Coin flip, UUID, and Hex strings.
- **Ranges & quantity:** pick a min/max (or dice sides / hex length) and roll one or many at once.
- **History:** every result is kept in a scrollable list with one-tap copy-to-clipboard.
- **Dark, gradient aesthetic** with a single-tap "Generate" action.

## Project layout

```
Shared/      SwiftUI app + RandomGenerator engine (shared by both targets)
MacApp/      macOS entry point + Info.plist + assets
iOSApp/      iOS entry point + Info.plist + assets
project.yml  XcodeGen manifest (generates NumberTwo.xcodeproj)
scripts/     CI build / archive / TestFlight helpers
.github/     GitHub Actions CI (iOS + macOS, unsigned by default)
```

## Local build

```sh
brew install xcodegen
xcodegen generate
open NumberTwo.xcodeproj
```

## CI

Pushing to `main` (or opening a PR against it) triggers
`.github/workflows/ci-build.yml`, which generates the project with XcodeGen
and builds the macOS + iOS schemes on a GitHub runner. Set the Apple
signing / App Store Connect secrets in repo Settings to enable TestFlight
uploads.

## License

MIT
