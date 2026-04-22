# Square Breath

Minimalist single-page Flutter app for the Square Breathing technique.

## Overview

This app guides breathing with a repeating 4-4-4-4 pattern:

- Inhale (4s)
- Hold (4s)
- Exhale (4s)
- Hold (4s)

The session is presented with a calm visual pulse, text phase cues, per-phase countdown, subtle haptic transitions, and wake lock to keep the screen on while practicing.

## Features

- Single-screen, minimal UI
- Two session modes:
  - Fixed Timer (default: 5 minutes)
  - Number of Rounds
- Animated rounded rectangle breath guide:
  - Inhale: grows
  - Hold: stays large
  - Exhale: shrinks
  - Hold: stays small
- Smooth phase transitions with `AnimationController` and `Curves.easeInOut`
- Subtle haptic feedback on each phase start
- Screen wake lock during active session

## Tech Stack

- Flutter (Dart)
- `google_fonts` (Montserrat typography)
- `haptic_feedback` (phase tactile cues)
- `wakelock_plus` (prevent screen sleep during session)

## Requirements

- Flutter SDK installed and available in PATH
- A connected Android/iOS device or an emulator/simulator

Check environment:

```bash
flutter doctor
```

## Setup

From project root:

```bash
flutter pub get
```

## Run

Start on the selected device:

```bash
flutter run
```

If multiple devices are connected, list them and select one:

```bash
flutter devices
flutter run -d <device_id>
```

```bash
flutter build apk --release
```
If you want to reduce the file size for specific devices:

```bash
flutter build apk --split-per-abi
```


## Quality Checks

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

## Project Structure

- `lib/main.dart`: App UI, breathing state machine, animation, haptics, wake lock integration
- `test/widget_test.dart`: Basic UI smoke test

## Notes

- Default mode is **Fixed Timer** at **5 minutes**.
- Wake lock is enabled on session start and disabled on stop/end.
- Haptic calls are wrapped defensively to avoid interrupting the session on unsupported devices.
